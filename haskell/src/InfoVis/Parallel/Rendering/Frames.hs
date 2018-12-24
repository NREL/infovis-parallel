{-# LANGUAGE RecordWildCards #-}


module InfoVis.Parallel.Rendering.Frames (
  Frame
, makeFrame
, drawFrame
) where


import Data.List (unzip4)
import Graphics.Rendering.OpenGL.GL.Tensor (Vector3(..), Vector4(..), Vertex3(..))
import InfoVis.Parallel.NewTypes (Geometry(..), Identifier, Shape(..))
import InfoVis.Parallel.Rendering.Buffers (ShapeBuffer, createShapeBuffer, drawInstances, insertPositions, updateColors, updateRotations, updateScales, prepareShapeBuffer)
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
          -> [(Identifier, Geometry)]
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
      geometries :: M.Map Identifier Geometry
    , buffer     :: ShapeBuffer
    }
  | LabelFrame
    {
      geometries :: M.Map Identifier Geometry
    }


drawGeometryFrame :: Real a
                  => M44 a
                  -> M44 a
                  -> GeometryFrame
                  -> IO ()
drawGeometryFrame projection modelView shapeFrame@ShapeFrame{..} =
  drawInstances
    (fmap realToFrac <$> projection)
    (fmap realToFrac <$> modelView)
    buffer


makeGeometryFrame :: ShapeProgram
                  -> [(Identifier, Geometry)]
                  -> IO GeometryFrame
makeGeometryFrame program gs =
  do
    let
      (positions, rotations, scales, colors) =
        unzip4
          [
            (
              (
                identifier
              , case shape of
                  Points pss -> (\(P (V3 x y z)) -> realToFrac <$> Vertex3 x y z) <$> concat pss
                  _          -> []
              )
            , (identifier, Vector4 0 0 0 1                      )
            , (identifier, realToFrac <$> Vector3 size size size)
            , (identifier, color                                )
            )
          |
            (identifier, Geometry{..}) <- gs
          ]
      geometries = M.fromList gs
    buffer' <-
      updateColors colors
      . updateScales scales
      . updateRotations rotations
      . insertPositions positions
      <$>  createShapeBuffer 10000 program (cube 1)
    buffer <- prepareShapeBuffer buffer'
    return ShapeFrame{..} 
