{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RecordWildCards  #-}
{-# LANGUAGE TypeFamilies     #-}


module InfoVis.Parallel.Rendering.Frames (
  Manager
, createManager
, destroyManager
, set
, listFrames
, insert
, delete
, reset
, prepare
, draw
) where


import Control.Lens.Lens (Lens', (&), lens)
import Control.Lens.Setter ((.~), over)
import Control.Lens.Traversal (traverseOf)
import Control.Monad (ap, unless)
import Data.Bits ((.&.), shift)
import Data.Default (def)
import Data.Maybe (fromMaybe)
import Graphics.GL.Types (GLfloat)
import Graphics.Rendering.OpenGL.GL.CoordTrans (preservingMatrix)
import Graphics.Rendering.OpenGL.GL.Tensor (Vector3(..), Vector4(..), Vertex3(..))
import Graphics.Rendering.OpenGL.GL.VertexSpec (Color4(..))
import Graphics.UI.GLUT.Fonts (StrokeFont(MonoRoman), fontHeight, renderString)
import InfoVis.Parallel.NewTypes (DeltaGeometry(..), Geometry(..), Glyph(..), Identifier, Shape(..))
import InfoVis.Parallel.Rendering.Buffers (ShapeBuffer, createShapeBuffer, deleteInstance, destroyShapeBuffer, drawInstances, insertPositions, updateColor, updateRotations, updateScales, prepareShapeBuffer)
import InfoVis.Parallel.Rendering.NewShapes (Mesh, arrow, cube, icosahedron, square, tube)
import InfoVis.Parallel.Rendering.Program (ShapeProgram, prepareShapeProgram)
import Linear.Affine (Point(..), (.-.), (.+^))
import Linear.Metric (norm)
import Linear.Quaternion (Quaternion(..), rotate)
import Linear.Util (rotationFromPlane, rotationFromVectorPair)
import Linear.V3 (V3(..))
import Linear.Vector (zero)

import qualified Data.Map.Strict as M (Map, (!), alter, delete, elems, empty, findWithDefault, fromList, keys, insert, lookup, map, mapWithKey, null)
import qualified Graphics.Rendering.OpenGL.GL.CoordTrans as G (scale, translate)
import qualified Graphics.Rendering.OpenGL.GL.VertexSpec as G (color)
import qualified InfoVis.Parallel.NewTypes as I (Frame)
import qualified Linear.Util.Graphics as G (toRotation, toVector3)


type FrameNumber = I.Frame


data Manager =
  Manager
  {
    program :: ShapeProgram
  , frames  :: M.Map FrameNumber Frame
  , current :: FrameNumber
  }


framesLens :: Lens' Manager (M.Map FrameNumber Frame)
framesLens = lens frames $ \s x -> s {frames = x}


currentLens :: Lens' Manager FrameNumber
currentLens = lens current $ \s x -> s {current = x}


set :: FrameNumber
    -> Manager
    -> Manager
set = (currentLens .~)


listFrames :: Manager
           -> [FrameNumber]
listFrames = M.keys . frames


createManager :: IO Manager
createManager =
  do
    let
      frames = M.empty
      current = error "The current frame has not been set."
    program <- prepareShapeProgram
    return Manager{..}


destroyManager :: Manager
               -> IO ()
destroyManager = mapM_ destroyFrame . frames


reset :: Manager
      -> Manager
reset =
  over framesLens
    $ M.map resetFrame


insert :: [DeltaGeometry]
       -> Manager
       -> Manager
insert = flip $ foldl insert' 


insert' :: Manager
        -> DeltaGeometry
        -> Manager
insert' manager@Manager{..} geometry@DeltaGeometry{..} =
  manager
    & over framesLens
      (
        M.alter
          (Just . (`insertFrame` geometry) . fromMaybe (createFrame program))
          frame
      )
    & over currentLens
      (
        if M.null frames
          then const frame
          else id
      )


delete :: [Identifier]
       -> Manager
       -> Manager
delete identifiers manager =
  manager
    & over framesLens
      (M.map (`deleteFrame` identifiers))


prepare :: Manager
        -> IO Manager
prepare = traverseOf framesLens $ mapM prepareFrame


draw :: Manager
     -> IO ()
draw Manager{..} =
  unless (M.null frames)
    . drawFrame
    $ frames M.! current


data ShapeMesh =
    CubeMesh
  | SphereMesh
  | PolylineMesh
  | RectangleMesh
  | LabelMesh
  | AxisMesh
    deriving (Bounded, Enum, Eq, Ord, Read, Show)


mesh :: ShapeMesh
     -> Mesh GLfloat
mesh CubeMesh      = cube 1
mesh SphereMesh    = icosahedron 1
mesh PolylineMesh  = tube 1 1
mesh RectangleMesh = square 1
mesh LabelMesh     = undefined
mesh AxisMesh      = arrow 1 1 0.1 2


findShapeMesh :: Shape
              -> ShapeMesh
findShapeMesh shape =
  case shape of
    Points     Cube   _ -> CubeMesh
    Points     Sphere _ -> SphereMesh
    Polylines         _ -> PolylineMesh
    Rectangles        _ -> RectangleMesh
    Label             _ -> LabelMesh
    Axis              _ -> AxisMesh


type Frame = M.Map ShapeMesh Display


createFrame :: ShapeProgram
            -> Frame
createFrame program =
  M.fromList
    $ ap (,) (createDisplay program)
    <$> [minBound..maxBound]


destroyFrame :: Frame
             -> IO ()
destroyFrame = mapM_ destroyDisplay


resetFrame :: Frame
           -> Frame
resetFrame = M.map resetDisplay


insertFrame :: Frame
            -> DeltaGeometry
            -> Frame
insertFrame frame deltaGeometry = M.mapWithKey (insertDisplay deltaGeometry) frame      


deleteFrame :: Frame
            -> [Identifier]
            -> Frame
deleteFrame frame identifiers = M.map (`deleteDisplay` identifiers) frame 


prepareFrame :: Frame
             -> IO Frame
prepareFrame = mapM prepareDisplay


drawFrame :: Frame
          -> IO ()
drawFrame = mapM_ drawDisplay


data Display =
    ShapeDisplay
    {
      geometries :: M.Map Identifier Geometry
    , buffer     :: ShapeBuffer
    }
  | LabelDisplay
    {
      geometries :: M.Map Identifier Geometry
    }


resetDisplay :: Display
             -> Display
resetDisplay = ap deleteDisplay (M.keys . geometries)


geometriesLens :: Lens' Display (M.Map Identifier Geometry)
geometriesLens = lens geometries $ \s x -> s {geometries = x}


bufferLens :: Lens' Display ShapeBuffer
bufferLens = lens buffer $ \s x -> s {buffer = x}


createDisplay :: ShapeProgram
              -> ShapeMesh
              -> Display
createDisplay _       LabelMesh = LabelDisplay M.empty
createDisplay program shapeMesh = ShapeDisplay M.empty $ createShapeBuffer program (mesh shapeMesh)


destroyDisplay :: Display
               -> IO ()
destroyDisplay LabelDisplay{}   = return ()
destroyDisplay ShapeDisplay{..} = destroyShapeBuffer buffer
        
   
prepareDisplay :: Display
               -> IO Display
prepareDisplay display@LabelDisplay{}   = return display
prepareDisplay display@ShapeDisplay{..} = display & traverseOf bufferLens prepareShapeBuffer


drawDisplay :: Display
            -> IO ()
drawDisplay LabelDisplay{..} =
  do
    fh <- fontHeight MonoRoman
    sequence_
      [
        preservingMatrix
          $ do
            G.color
              $ Color4
                (fromIntegral ((0xFF000000 .&. color) `shift` (-24)) / 255           )
                (fromIntegral ((0x00FF0000 .&. color) `shift` (-16)) / 255           )
                (fromIntegral ((0x0000FF00 .&. color) `shift` ( -8)) / 255           )
                (fromIntegral ( 0x000000FF .&. color               ) / 255 :: GLfloat)
            G.translate $ G.toVector3 o'
            G.toRotation q
            G.scale s s s
            G.translate $ Vector3 0 (0.1 * fh) 0
            renderString MonoRoman text
      |
        Geometry{..} <- M.elems geometries
      , let
          Label (o, w, h) = shape
          o' = o .-. zero
          q = rotationFromPlane (V3 1 0 0) (V3 0 1 0) o w h
          s = realToFrac size / fh
      ]      
drawDisplay ShapeDisplay{..} =
  drawInstances
    buffer


merge :: Geometry
      -> DeltaGeometry
      -> Geometry
merge Geometry{..} DeltaGeometry{..} =
  Geometry
  {
    shape = case (deltaShape, deltaGlyph) of
              (Just (Points _ pps), Just g') -> Points g' pps
              (Just shape'        , _      ) -> shape'
              _                              -> shape
  , size  = fromMaybe size  deltaSize
  , color = fromMaybe color deltaColor
  , text  = fromMaybe text  deltaText
  }


data Revision =
    Insertion
  | Deletion
  | Recoloring
  | None


revision :: ShapeMesh
         -> DeltaGeometry
         -> M.Map Identifier Geometry
         -> Revision
revision shapeMesh DeltaGeometry{..} geometries' =
  let
    old = identifier `M.lookup` geometries'
    Just shapeMesh' = findShapeMesh <$> deltaShape
    CubeMesh   `morph` SphereMesh = True
    SphereMesh `morph` CubeMesh   = True
    _          `morph` _          = False
  in
    case (old, deltaShape, deltaSize, deltaColor, shapeMesh == shapeMesh', shapeMesh `morph` shapeMesh') of
      (Nothing, Just _, _     , _     , True , _    ) -> Insertion
      (Nothing, _     , _     , _     , _    , _    ) -> None
      (_      , Just _, _     , _     , False, True ) -> Deletion
      (_      , Just _, _     , _     , False, _    ) -> None
      (_      , Just _, _     , _     , _    , _    ) -> Insertion
      (_      , _     , Just _, _     , _    , _    ) -> Insertion
      (_      , _     , _     , Just _, _    , _    ) -> Recoloring
      (_      , _     , _     , _     , _    , _    ) -> None


deleteDisplay :: Display
              -> [Identifier]
              -> Display
deleteDisplay display@LabelDisplay{..} identifiers =
  display
    & over geometriesLens
      (flip (foldl (flip M.delete)) identifiers)
deleteDisplay display@ShapeDisplay{..} identifiers =
  display
    & over geometriesLens
      (flip (foldl (flip M.delete)) identifiers)
    & over bufferLens
      (flip (foldl deleteInstance) identifiers)


insertDisplay :: DeltaGeometry
              -> ShapeMesh
              -> Display
              -> Display
insertDisplay deltaGeometry@DeltaGeometry{..} shapeMesh display@LabelDisplay{..} =
  let
    old = M.findWithDefault def identifier geometries
    new = old `merge` deltaGeometry
  in
    case revision shapeMesh deltaGeometry geometries of
      None      -> display
      Deletion  -> display
                     & over geometriesLens (M.delete identifier)
      _         -> display
                     & over geometriesLens (M.insert identifier new)
insertDisplay deltaGeometry@DeltaGeometry{..} shapeMesh display@ShapeDisplay{..} =
  let
    old = M.findWithDefault def identifier geometries
    new = old `merge` deltaGeometry
  in
    case revision shapeMesh deltaGeometry geometries of
      None      -> display
      Deletion  -> display
                     & over geometriesLens (M.delete identifier)
                     & over bufferLens     (`deleteInstance` identifier)
      Insertion -> display
                     & over geometriesLens (M.insert identifier new)
                     & over bufferLens     (updateDisplay (identifier, new) . flip deleteInstance identifier)
      Recoloring-> display
                     & over geometriesLens (M.insert identifier new)
                     & over bufferLens     (updateColor (identifier, color new))
    

updateDisplay :: (Identifier, Geometry)
              -> ShapeBuffer
              -> ShapeBuffer
updateDisplay (identifier, Geometry{..}) =
  let
    noRotation = Quaternion 1 $ V3 0 0 0
    right = V3 1 0 0
    back = V3 0 0 1
    toPosition (P (V3 x y z)) = realToFrac <$> Vertex3 x y z
    toRotation (Quaternion w (V3 x y z)) = realToFrac <$> Vector4 x y z w
    toScale (V3 x y z) = realToFrac <$> Vector3 x y z
    (positions, rotations, scales) =
      unzip3 $ case shape of
        Points _   pss -> let
                            make p = (p, noRotation, V3 size size size)
                          in
                            make <$> concat pss
        Polylines  pps -> let
                            make u0 u1 =
                              let
                                ud = u1 .-. u0
                                uc = u0 .+^ ud / 2
                              in
                                (
                                  uc
                                , rotationFromVectorPair right ud
                                , V3 (norm ud) size size
                                )
                          in
                            zipWith make (concatMap init pps) (concatMap tail pps)
        Rectangles pps -> let
                            make (o, u, v) =
                              let
                                w = norm $ u .-. o
                                h = norm $ v .-. o
                                q = rotationFromPlane right back o u v
                              in
                                (
                                  o .+^ q `rotate` V3 (w / 2) 0 (h / 2)
                                , q
                                , V3 w size h
                                )
                          in
                            make <$> pps
        Label      _   -> undefined
        Axis  (u0, u1) -> let
                            ud = u1 .-. u0
                            uc = u0 .+^ ud / 2
                          in
                            [(
                              uc
                            , rotationFromVectorPair right ud
                            , V3 (norm ud) size size
                            )]
  in
      updateColor     (identifier,                color    )
    . updateScales    (identifier, toScale    <$> scales   )
    . updateRotations (identifier, toRotation <$> rotations)
    . insertPositions (identifier, toPosition <$> positions)
