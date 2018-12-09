{-# LANGUAGE RecordWildCards #-}


module InfoVis.Parallel.Rendering.Buffers (
  ShapeBuffer
, makeShapeBuffer
, updateInstances
, drawInstances
, buildBuffer
) where


import Data.Array.Storable (newListArray, withStorableArray)
import Data.Maybe (catMaybes)
import Foreign.Storable (Storable, sizeOf)
import Graphics.GL.Types (GLfloat, GLuint)
import Graphics.Rendering.OpenGL.GL (($=!), genObjectName)
import Graphics.Rendering.OpenGL.GL.BufferObjects (BufferObject, BufferTarget(..), BufferUsage(DynamicDraw), bindBuffer, bufferData)
import Graphics.Rendering.OpenGL.GL.PrimitiveMode (PrimitiveMode(..))
import Graphics.Rendering.OpenGL.GL.Tensor (Vector3(..), Vector4(..), Vertex3(..))
import Graphics.Rendering.OpenGL.GL.VertexArrays (NumArrayIndices, NumInstances, drawArraysInstanced)
import InfoVis.Parallel.Rendering.Program -- FIXME
import Linear.Matrix (M44)


data ShapeBuffer =
  ShapeBuffer
  {
    shapeProgram  :: ShapeProgram
  , primitiveMode :: PrimitiveMode
  , mesh          :: BufferObject
  , vertexCount   :: NumArrayIndices
  , instanceCount :: NumInstances
  , positions     :: Maybe BufferObject
  , rotations     :: Maybe BufferObject
  , scales        :: Maybe BufferObject
  , colors        :: Maybe BufferObject
  }


makeShapeBuffer :: ShapeProgram
                -> (PrimitiveMode, [Vertex3 GLfloat])
                -> IO ShapeBuffer
makeShapeBuffer shapeProgram (primitiveMode, primitives) =
  do
    mesh <- buildBuffer primitives
    let
      vertexCount   = fromIntegral $ length primitives
      instanceCount = 0
      positions = Nothing
      rotations = Nothing
      scales    = Nothing
      colors    = Nothing
    return ShapeBuffer{..}


updateInstances :: Maybe [Vertex3 GLfloat]
                -> Maybe [Vector4 GLfloat]
                -> Maybe [Vector3 GLfloat]
                -> Maybe [GLuint]
                -> ShapeBuffer
                -> IO ShapeBuffer
updateInstances positions' rotations' scales' colors' shapeBuffer@ShapeBuffer{..} =
  do
    let
      instanceCount' = catMaybes [length <$> positions', length <$> rotations', length <$> scales', length <$> colors']
    positions'' <- maybe (return positions) (fmap Just . buildBuffer) positions'
    rotations'' <- maybe (return rotations) (fmap Just . buildBuffer) rotations'
    scales''    <- maybe (return scales   ) (fmap Just . buildBuffer) scales'
    colors''    <- maybe (return colors   ) (fmap Just . buildBuffer) colors'
    return
      shapeBuffer
      {
        instanceCount = if null instanceCount' then instanceCount else fromIntegral (head instanceCount')
      , positions     = positions''
      , rotations     = rotations''
      , scales        = scales''
      , colors        = colors''
      }


drawInstances :: ShapeBuffer
              -> M44 GLfloat
              -> M44 GLfloat
              -> IO ()
drawInstances ShapeBuffer{..} projection modelView =
  do

    selectProgram $ Just shapeProgram

    setProjectionModelView shapeProgram projection modelView 

    shapeProgram `bindMesh`      Just mesh
    shapeProgram `bindPositions` positions
    shapeProgram `bindRotations` rotations
    shapeProgram `bindScales`    scales
    shapeProgram `bindColors`    colors

    drawArraysInstanced primitiveMode 0 vertexCount instanceCount

    selectProgram Nothing


buildBuffer :: Storable a
            => [a]
            -> IO BufferObject
buildBuffer primitives =
  do
    let
      m = sizeOf $ head primitives
      n = length primitives
      size = n * m
    bufferObject <- genObjectName
    bindBuffer ArrayBuffer $=! Just bufferObject
    values <- newListArray (0, size) primitives
    withStorableArray values
      $ \ptr ->
        bufferData ArrayBuffer $=! (toEnum size, ptr, DynamicDraw)
    bindBuffer ArrayBuffer $=! Nothing
    return bufferObject
