{-# LANGUAGE RecordWildCards #-}


module InfoVis.Parallel.Rendering.Frames (
  Frame
, makeFrame
, drawFrame
) where


import Graphics.Rendering.OpenGL.GL.Tensor (Vector3(..), Vector4(..), Vertex3(..))
import InfoVis.Parallel.NewTypes (Geometry(..), Identifier, Shape(..))
import InfoVis.Parallel.Rendering.Buffers (ShapeBuffer, ShapeSection(..), drawInstances, makeShapeBuffer, setInstances)
import InfoVis.Parallel.Rendering.NewShapes (cube)
import InfoVis.Parallel.Rendering.Program (ShapeProgram)
import Linear.Affine (Point(..))
import Linear.Matrix (M44)
import Linear.V3 (V3(..))

import qualified Data.Map.Strict as M


data Frame = 
  Frame
  {
    pointGeometries     :: GeometryFrame
  , polylineGeometries  :: GeometryFrame
  , rectangleGeometries :: GeometryFrame
  , labelGeometries     :: GeometryFrame
  , axisGeometries      :: GeometryFrame
  }


makeFrame :: ShapeProgram
          -> [Geometry]
          -> IO Frame
makeFrame program gs =
  do
    pointGeometries     <- makeGeometryFrame program gs
    polylineGeometries  <- makeGeometryFrame program []
    rectangleGeometries <- makeGeometryFrame program []
    labelGeometries     <- makeGeometryFrame program []
    axisGeometries      <- makeGeometryFrame program []
    return Frame{..}


drawFrame :: Real a
          => M44 a
          -> M44 a
          -> Frame
          -> IO ()
drawFrame projection modelView Frame{..} =
  mapM_
    (drawGeometryFrame projection modelView)
    [pointGeometries, polylineGeometries, rectangleGeometries, labelGeometries, axisGeometries]


data GeometryFrame =
    ShapeFrame
    {
      geometries :: M.Map Identifier [Geometry]
    , buffer     :: ShapeBuffer
    }
  | LabelFrame
    {
      geometries :: M.Map Identifier [Geometry]
    }


drawGeometryFrame :: Real a
                  => M44 a
                  -> M44 a
                  -> GeometryFrame
                  -> IO ()
drawGeometryFrame projection modelView ShapeFrame{..} =
  drawInstances
    (fmap realToFrac <$> projection)
    (fmap realToFrac <$> modelView)
    buffer


makeGeometryFrame :: ShapeProgram
                  -> [Geometry]
                  -> IO GeometryFrame
makeGeometryFrame program gs =
  do
    let
      section = mconcat $ makeSection <$> gs
      geometries = M.empty
    buffer <- makeShapeBuffer program (cube 1) >>= setInstances section
    return ShapeFrame{..} 


makeSection :: Geometry
            -> ShapeSection
makeSection Geometry{..} =
  let
    (positionSection, rotationSection, scaleSection) =
      case shape of
        Points pss -> let
                        points = (\(P (V3 x y z)) -> realToFrac <$> Vertex3 x y z) <$> concat pss
                        n = length points
                      in
                        (
                          points
                        , replicate n $ Vector4 0 0 0 1
                        , replicate n $ realToFrac <$> Vector3 size size size
                        )
    colorSection = replicate (length positionSection) color
  in
    ShapeSection{..}
