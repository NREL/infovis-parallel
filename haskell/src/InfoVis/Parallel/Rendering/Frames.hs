{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RecordWildCards  #-}
{-# LANGUAGE TypeFamilies     #-}


module InfoVis.Parallel.Rendering.Frames (
  Manager
, createManager
, destroyManager
, setFrame
, addFrame
, insert
, prepare
, draw
) where


import Control.Monad (liftM2)
import Data.Bits ((.&.), shift)
import Graphics.GL.Types (GLfloat)
import Graphics.Rendering.OpenGL.GL.CoordTrans (MatrixComponent, preservingMatrix)
import Graphics.Rendering.OpenGL.GL.Tensor (Vector3(..), Vector4(..), Vertex3(..))
import Graphics.Rendering.OpenGL.GL.VertexSpec (Color4(..))
import Graphics.UI.GLUT.Fonts (StrokeFont(MonoRoman), fontHeight, renderString)
import InfoVis.Parallel.NewTypes (Geometry(..), Glyph(..), Identifier, Shape(..))
import InfoVis.Parallel.Rendering.Buffers (ShapeBuffer, createShapeBuffer, destroyShapeBuffer, drawInstances, insertPositions, updateColor, updateRotations, updateScales, prepareShapeBuffer)
import InfoVis.Parallel.Rendering.NewShapes (Mesh, arrow, cube, icosahedron, square, tube)
import InfoVis.Parallel.Rendering.Program (ShapeProgram, prepareShapeProgram, setProjectionModelView')
import Linear.Affine (Point(..), (.-.), (.+^))
import Linear.Matrix (M44)
import Linear.Metric (norm)
import Linear.Quaternion (Quaternion(..), rotate)
import Linear.Util (rotationFromPlane, rotationFromVectorPair)
import Linear.V3 (V3(..))
import Linear.Vector (zero)

import qualified Data.Map.Strict as M (Map, (!), adjust, elems, empty, fromList, insert, toList)
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


setFrame :: FrameNumber
         -> Manager
         -> Manager
setFrame frame frameManager =
  frameManager
  {
    current = frame
  }


createManager :: IO Manager
createManager =
  do
    let
      frames = M.empty
      current = undefined
    program <- prepareShapeProgram
    return Manager{..}


destroyManager :: Manager
               -> IO ()
destroyManager Manager{..} = mapM_ destroyFrame $ M.elems frames


addFrame :: FrameNumber
         -> Manager
         -> IO Manager
addFrame frame frameManager@Manager{..} =
  do
    newFrame <- createFrame program
    return
      frameManager
      {
        frames = M.insert frame newFrame frames
      }


insert :: Manager
       -> FrameNumber
       -> [(Identifier, Geometry)]
       -> Manager
insert frameManager@Manager{..} frameNumber identifierGeometries =
  let
    frame = insertFrame (frames M.! frameNumber) identifierGeometries
  in
    frameManager
    {
      frames = M.insert frameNumber frame frames
    }


prepare :: FrameNumber
        -> Manager
        -> IO Manager
prepare frameNumber frameManager@Manager{..} =
  do
    frame <- prepareFrame $ frames M.! frameNumber
    return
      frameManager
      {
        frames = M.insert frameNumber frame frames
      }


draw :: (MatrixComponent a, Real a)
     => FrameNumber
     -> M44 a
     -> M44 a
     -> Manager
     -> IO ()
draw frameNumber projection modelView Manager{..} =
  drawFrame projection modelView
    $ frames M.! frameNumber


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


findShapeMesh :: Geometry
              -> ShapeMesh
findShapeMesh Geometry{..} =
  case shape of
    Points     Cube   _ -> CubeMesh
    Points     Sphere _ -> SphereMesh
    Polylines         _ -> PolylineMesh
    Rectangles        _ -> RectangleMesh
    Label             _ -> LabelMesh
    Axis              _ -> AxisMesh


newtype Frame =
  Frame
  {
    unFrame :: M.Map ShapeMesh Display
  }


createFrame :: ShapeProgram
            -> IO Frame
createFrame program =
  Frame
    . M.fromList
    <$> mapM (liftM2 fmap (,) $ createDisplay program) [minBound..maxBound]


destroyFrame :: Frame
             -> IO ()
destroyFrame Frame{..} = mapM_ destroyDisplay $ M.elems unFrame


insertFrame :: Frame
            -> [(Identifier, Geometry)]
            -> Frame
insertFrame Frame{..} =
  Frame
    . foldl
      (
        \unFrame' identifierGeometry@(_, geometry) ->
          M.adjust
            (insertDisplay identifierGeometry)
            (findShapeMesh geometry)
            unFrame'
      )
      unFrame


prepareFrame :: Frame
             -> IO Frame
prepareFrame =
  fmap (Frame . M.fromList)
    . mapM (uncurry ((. prepareDisplay) . (<$>) . (,)))
    . M.toList
    . unFrame


drawFrame :: (MatrixComponent a, Real a)
          => M44 a
          -> M44 a
          -> Frame
          -> IO ()
drawFrame projection modelView Frame{..} = mapM_ (drawDisplay projection modelView) $ M.elems unFrame


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


createDisplay :: ShapeProgram
              -> ShapeMesh
              -> IO Display
createDisplay _ LabelMesh =
  let
    geometries = M.empty
  in
    return LabelDisplay{..}
createDisplay program shapeMesh =
  do
    buffer <- createShapeBuffer 10000 program $ mesh shapeMesh
    let
      geometries = M.empty
    return ShapeDisplay{..}


destroyDisplay :: Display
               -> IO ()
destroyDisplay LabelDisplay{}   = return ()
destroyDisplay ShapeDisplay{..} = destroyShapeBuffer buffer
        
   
prepareDisplay :: Display
               -> IO Display
prepareDisplay display@LabelDisplay{} =
  return display
prepareDisplay display@ShapeDisplay{..} =
  do
    buffer' <- prepareShapeBuffer buffer
    return
      display
      {
        buffer = buffer'
      }


drawDisplay :: (MatrixComponent a, Real a)
            => M44 a
            -> M44 a
            -> Display
            -> IO ()
drawDisplay projection modelView LabelDisplay{..} =
  do
    fh <- fontHeight MonoRoman
    setProjectionModelView' projection modelView
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
            G.translate $ Vector3 0 (0.25 * fh) 0
--          G.translate $ Vector3 0 (33.33 / (119.05 + 33.33) * fh) 0
            renderString MonoRoman text
      |
        Geometry{..} <- M.elems geometries
      , let
          Label (o, w, h) = shape
          o' = o .-. zero
          h' = h .-. o
          q = rotationFromPlane (V3 1 0 0) (V3 0 1 0) o w h
          s = realToFrac (norm h') / fh
      ]      
drawDisplay projection modelView ShapeDisplay{..} =
  drawInstances
    (fmap realToFrac <$> projection)
    (fmap realToFrac <$> modelView )
    buffer


insertDisplay :: (Identifier, Geometry)
              -> Display
              -> Display
insertDisplay (identifier, geometry) display@LabelDisplay{..} =
  display
  {
    geometries = M.insert identifier geometry geometries
  }
insertDisplay (identifier, geometry@Geometry{..}) display@ShapeDisplay{..} =
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
    display
    {
      geometries = M.insert identifier geometry geometries
    , buffer     =   updateColor     (identifier,                color    )
                   . updateScales    (identifier, toScale    <$> scales   )
                   . updateRotations (identifier, toRotation <$> rotations)
                   $ insertPositions (identifier, toPosition <$> positions) buffer
    }
