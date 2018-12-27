{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RecordWildCards  #-}
{-# LANGUAGE TypeFamilies     #-}


module InfoVis.Parallel.Rendering.Frames (
  Frame
, createFrame
, destroyFrame
, insertFrame
, prepareFrame
, drawFrame
) where


import Control.Monad (liftM2)
import Data.List (zipWith4)
import Debug.Trace (trace)
import Graphics.GL.Types (GLfloat)
import Graphics.Rendering.OpenGL.GL.Tensor (Vector3(..), Vector4(..), Vertex3(..))
import InfoVis.Parallel.NewTypes (Geometry(..), Glyph(..), Identifier, Shape(..))
import InfoVis.Parallel.Rendering.Buffers (ShapeBuffer, createShapeBuffer, destroyShapeBuffer, drawInstances, insertPositions, updateColor, updateRotations, updateScales, prepareShapeBuffer)
import InfoVis.Parallel.Rendering.NewShapes (Mesh, arrow, cube, icosahedron, square, tube)
import InfoVis.Parallel.Rendering.Program (ShapeProgram)
import Linear.Affine (Point(..), (.-.), (.+^))
import Linear.Matrix (M44)
import Linear.Metric (norm)
import Linear.Quaternion (Quaternion(..), rotate)
import Linear.Util (rotationFromPlane, rotationFromVectorPair)
import Linear.V3 (V3(..))

import qualified Data.Map.Strict as M (Map, adjust, elems, empty, fromList, insert, toList)


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
    unFrame :: M.Map ShapeMesh GeometryFrame
  }


createFrame :: ShapeProgram
            -> IO Frame
createFrame program =
  Frame
    . M.fromList
    <$> mapM (liftM2 fmap (,) $ createGeometryFrame program) [minBound..maxBound]


destroyFrame :: Frame
             -> IO ()
destroyFrame Frame{..} = mapM_ destroyGeometryFrame $ M.elems unFrame


insertFrame :: Frame
            -> [(Identifier, Geometry)]
            -> Frame
insertFrame Frame{..} =
  Frame
    . foldl
      (
        \unFrame' identifierGeometry@(_, geometry) ->
          M.adjust
            (insertGeometryFrame identifierGeometry)
            (findShapeMesh geometry)
            unFrame'
      )
      unFrame


prepareFrame :: Frame
             -> IO Frame
prepareFrame =
  fmap (Frame . M.fromList)
    . mapM (uncurry ((. prepareGeometryFrame) . (<$>) . (,)))
    . M.toList
    . unFrame


drawFrame :: Real a
          => M44 a
          -> M44 a
          -> Frame
          -> IO ()
drawFrame projection modelView Frame{..} = mapM_ (drawGeometryFrame projection modelView) $ M.elems unFrame


data GeometryFrame =
    ShapeFrame
    {
      geometries :: M.Map Identifier Geometry
    , buffer     :: ShapeBuffer
    }
  | LabelFrame
    {
      geometries :: M.Map Identifier Geometry
    }


createGeometryFrame :: ShapeProgram
                    -> ShapeMesh
                    -> IO GeometryFrame
createGeometryFrame _ LabelMesh =
  let
    geometries = M.empty
  in
    return LabelFrame{..}
createGeometryFrame program shapeMesh =
  do
    buffer <- createShapeBuffer 10000 program $ mesh shapeMesh
    let
      geometries = M.empty
    return ShapeFrame{..}


destroyGeometryFrame :: GeometryFrame -> IO ()
destroyGeometryFrame LabelFrame{}   = return ()
destroyGeometryFrame ShapeFrame{..} = destroyShapeBuffer buffer
        
   
prepareGeometryFrame :: GeometryFrame
                     -> IO GeometryFrame
prepareGeometryFrame geometryFrame@LabelFrame{} =
  return geometryFrame
prepareGeometryFrame geometryFrame@ShapeFrame{..} =
  do
    buffer' <- prepareShapeBuffer buffer
    return
      geometryFrame
      {
        buffer = buffer'
      }


drawGeometryFrame :: Real a
                  => M44 a
                  -> M44 a
                  -> GeometryFrame
                  -> IO ()
drawGeometryFrame _ _ LabelFrame{..} =
  return ()
drawGeometryFrame projection modelView ShapeFrame{..} =
  drawInstances
    (fmap realToFrac <$> projection)
    (fmap realToFrac <$> modelView )
    buffer


insertGeometryFrame :: (Identifier, Geometry)
                    -> GeometryFrame
                    -> GeometryFrame
insertGeometryFrame _ geometryFrame@LabelFrame{} =
  geometryFrame
insertGeometryFrame (identifier, geometry@Geometry{..}) geometryFrame@ShapeFrame{..} =
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
    geometryFrame
    {
      geometries = M.insert identifier geometry geometries
    , buffer     =   updateColor     (identifier,                color    )
                   . updateScales    (identifier, toScale    <$> scales   )
                   . updateRotations (identifier, toRotation <$> rotations)
                   $ insertPositions (identifier, toPosition <$> positions) buffer
    }
