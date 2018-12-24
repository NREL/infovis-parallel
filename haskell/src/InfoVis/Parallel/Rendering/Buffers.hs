{-# LANGUAGE RecordWildCards #-}


module InfoVis.Parallel.Rendering.Buffers (
  ShapeBuffer
, createShapeBuffer
, prepareShapeBuffer
, deleteShapeBuffer
, insertPositions
, updatePositions
, updateRotations
, updateScales
, updateColors
, deleteInstances
, drawInstances
) where


import Control.Monad (unless)
import Data.Array.Storable (getElems, newArray, newListArray, touchStorableArray, withStorableArray)
import Foreign.Ptr (plusPtr)
import Foreign.Storable (Storable, poke, sizeOf)
import Graphics.GL.Types (GLfloat, GLuint)
import Graphics.Rendering.OpenGL.GL (($=!), deleteObjectName, deleteObjectNames, genObjectName)
import Graphics.Rendering.OpenGL.GL.BufferObjects (BufferAccess(WriteOnly), BufferObject, BufferTarget(..), BufferUsage(DynamicDraw), TransferDirection(ReadFromBuffer), bindBuffer, bufferData, bufferSubData, withMappedBuffer)
import Graphics.Rendering.OpenGL.GL.PrimitiveMode (PrimitiveMode(..))
import Graphics.Rendering.OpenGL.GL.Tensor (Vector3(..), Vector4(..), Vertex3(..))
import Graphics.Rendering.OpenGL.GL.VertexArrays (NumArrayIndices, NumInstances, drawArraysInstanced)
import InfoVis.Parallel.NewTypes (Identifier)
import InfoVis.Parallel.Rendering.Program (ShapeProgram, bindColors, bindMesh, bindPositions, bindRotations, bindScales, selectShapeProgram, setProjectionModelView)
import Linear.Matrix (M44)
import System.IO (hPrint, stderr)

import qualified Data.IntMap.Lazy as IM (IntMap, empty, findMin, fromList, insert, null, toList, union)
import qualified Data.Map.Strict as M (Map, (!), delete, empty, foldl, insertWith)
import qualified Data.IntSet as IS (IntSet, deleteFindMin, empty, findMax, foldl, fromList, null, singleton, toList, union)


zeroPosition :: Vertex3 GLfloat
zeroPosition = Vertex3 0 0 0


zeroRotation :: Vector4 GLfloat
zeroRotation = Vector4 0 0 0 0


zeroScale :: Vector3 GLfloat
zeroScale = Vector3 0 0 0


zeroColor :: GLuint
zeroColor = 0


data ShapeBuffer =
  ShapeBuffer
  {
    shapeProgram     :: ShapeProgram
  , primitiveMode    :: PrimitiveMode
  , mesh             :: BufferObject
  , vertexCount      :: NumArrayIndices
  , instanceCount    :: NumInstances
  , positions        :: BufferObject
  , rotations        :: BufferObject
  , scales           :: BufferObject
  , colors           :: BufferObject
  , size             :: Int
  , empties          :: IS.IntSet
  , locations        :: M.Map Identifier IS.IntSet
  , pendingPositions :: IM.IntMap (Vertex3 GLfloat)
  , pendingRotations :: IM.IntMap (Vector4 GLfloat)
  , pendingScales    :: IM.IntMap (Vector3 GLfloat)
  , pendingColors    :: IM.IntMap GLuint
  , pendingSize      :: Int
  }


createShapeBuffer :: Int
                  -> ShapeProgram
                  -> (PrimitiveMode, [Vertex3 GLfloat])
                  -> IO ShapeBuffer
createShapeBuffer size shapeProgram (primitiveMode, primitives) =
  do
    mesh      <- buildBuffer primitives
    positions <- buildBuffer $ replicate size zeroPosition
    rotations <- buildBuffer $ replicate size zeroRotation
    scales    <- buildBuffer $ replicate size zeroScale
    colors    <- buildBuffer $ replicate size zeroColor
    let
      vertexCount   = fromIntegral $ length primitives
      instanceCount = 0
      empties = IS.fromList [0..(size-1)]
      locations = M.empty
      pendingPositions = IM.empty
      pendingRotations = IM.empty
      pendingScales    = IM.empty
      pendingColors    = IM.empty
      pendingSize = size
    return ShapeBuffer{..}


deleteShapeBuffer :: ShapeBuffer
                  -> IO ()
deleteShapeBuffer ShapeBuffer{..} = deleteObjectNames [mesh, positions, rotations, scales, colors]


insertPositions :: [(Identifier, [Vertex3 GLfloat])]
                -> ShapeBuffer
                -> ShapeBuffer
insertPositions =
  flip (foldl $ uncurry . insertPosition)
    . concatMap (uncurry ((<$>) . (,)))


insertPosition :: ShapeBuffer
               -> Identifier
               -> Vertex3 GLfloat
               -> ShapeBuffer
insertPosition shapeBuffer@ShapeBuffer{..} identifier vertex =
  let
    (empties', pendingSize'') =
      if IS.null empties
        then let
               pendingSize' = 3 * pendingSize `div` 2 + 1
             in
               (
                 IS.fromList [pendingSize..(pendingSize'-1)]
               , pendingSize'
               )
        else (empties, pendingSize)
    (location, empties'') = IS.deleteFindMin empties'
  in
    shapeBuffer
    {
      empties          = empties''
    , locations        = M.insertWith IS.union identifier (IS.singleton location) locations
    , pendingPositions = IM.insert location vertex pendingPositions
    , pendingSize      = pendingSize''
    }


updatePositions :: [(Identifier, [Vertex3 GLfloat])]
                -> ShapeBuffer
                -> ShapeBuffer
updatePositions updates shapeBuffer@ShapeBuffer{..} =
  let
    pending =
      foldl
        (
          \pending' (identifier, vertices) ->
            let
              locations' = IS.toList $ locations M.! identifier
            in
              IM.fromList (zip locations' vertices)
                `IM.union` pending'
        )
        pendingPositions
        updates

  in
    shapeBuffer {pendingPositions = pending}

  
updateRotations :: [(Identifier, Vector4 GLfloat)]
                -> ShapeBuffer
                -> ShapeBuffer
updateRotations updates shapeBuffer@ShapeBuffer{..} = shapeBuffer {pendingRotations = updateAttributes locations updates pendingRotations}
 

updateScales :: [(Identifier, Vector3 GLfloat)]
             -> ShapeBuffer
             -> ShapeBuffer
updateScales updates shapeBuffer@ShapeBuffer{..} = shapeBuffer {pendingScales = updateAttributes locations updates pendingScales}
 

updateColors :: [(Identifier, GLuint)]
             -> ShapeBuffer
             -> ShapeBuffer
updateColors updates shapeBuffer@ShapeBuffer{..} = shapeBuffer {pendingColors = updateAttributes locations updates pendingColors}
 

updateAttributes :: M.Map Identifier IS.IntSet
                 -> [(Identifier, a)]
                 -> IM.IntMap a
                 -> IM.IntMap a
updateAttributes locations updates pending =
  foldl
    (
      \pending' (identifier, value) ->
        let
          locations' = locations M.! identifier
        in
          IS.foldl
            (flip $ flip IM.insert value)
            pending'
            locations'
    )
    pending
    updates



deleteInstances :: [Identifier]
                -> ShapeBuffer
                -> ShapeBuffer
deleteInstances identifiers shapeBuffer@ShapeBuffer{..} =
  let
    locations' = foldl (flip $ IS.union . (locations M.!)) IS.empty identifiers
  in
    shapeBuffer
    {
      empties       = empties `IS.union` locations'
    , locations     = foldl (flip M.delete) locations identifiers
    , pendingScales = IS.foldl (flip $ flip IM.insert zeroScale) pendingScales locations'
    }


prepareShapeBuffer :: ShapeBuffer
                   -> IO ShapeBuffer
prepareShapeBuffer = (>>= updateShapeBuffer) . expandShapeBuffer


updateShapeBuffer :: ShapeBuffer
                  -> IO ShapeBuffer
updateShapeBuffer shapeBuffer@ShapeBuffer{..} =
  if IM.null pendingPositions && IM.null pendingRotations && IM.null pendingScales && IM.null pendingColors
    then return shapeBuffer
    else do
           pendingPositions `updateBuffer` positions
           pendingRotations `updateBuffer` rotations
           pendingScales    `updateBuffer` scales
           pendingColors    `updateBuffer` colors
           return
             shapeBuffer
             {
               instanceCount    = fromIntegral $ IS.findMax (M.foldl IS.union (IS.singleton (-1)) locations) + 1
             , pendingPositions = IM.empty
             , pendingRotations = IM.empty
             , pendingScales    = IM.empty
             , pendingColors    = IM.empty
             }


expandShapeBuffer :: ShapeBuffer
                  -> IO ShapeBuffer
expandShapeBuffer shapeBuffer@ShapeBuffer{..} =
  if pendingSize <= size
    then return shapeBuffer
    else do
           positions' <- expandBuffer zeroPosition size pendingSize positions
           rotations' <- expandBuffer zeroRotation size pendingSize rotations
           scales'    <- expandBuffer zeroScale    size pendingSize scales
           colors'    <- expandBuffer zeroColor    size pendingSize colors
           return 
             shapeBuffer
             {
               size      = pendingSize
             , positions = positions'
             , rotations = rotations'
             , scales    = scales'
             , colors    = colors'
             } 


drawInstances :: M44 GLfloat
              -> M44 GLfloat
              -> ShapeBuffer
              -> IO ()
drawInstances projection modelView ShapeBuffer{..} =
  do
    selectShapeProgram $ Just shapeProgram
    setProjectionModelView shapeProgram projection modelView 
    shapeProgram `bindMesh`      Just mesh
    shapeProgram `bindPositions` Just positions
    shapeProgram `bindRotations` Just rotations
    shapeProgram `bindScales`    Just scales
    shapeProgram `bindColors`    Just colors
    drawArraysInstanced primitiveMode 0 vertexCount instanceCount
    selectShapeProgram Nothing


buildBuffer :: Storable a
            => [a]
            -> IO BufferObject
buildBuffer primitives =
  do
    let
      stride = sizeOf $ head primitives
      size = length primitives
    bufferObject <- genObjectName
    bindBuffer ArrayBuffer $=! Just bufferObject
    values <- newListArray (0, size) primitives
    withStorableArray values
      $ \ptr ->
        bufferData ArrayBuffer $=! (fromIntegral $ size * stride, ptr, DynamicDraw)
    bindBuffer ArrayBuffer $=! Nothing
    return bufferObject


updateBuffer :: Storable a
             => IM.IntMap a
             -> BufferObject
             -> IO ()
updateBuffer updates bufferObject =
  unless (IM.null updates)
    $ do
      let
        stride = sizeOf . snd $ IM.findMin updates
      bindBuffer ArrayBuffer $=! Just bufferObject
      withMappedBuffer ArrayBuffer WriteOnly
        (
          \ptr ->
            sequence_
              [
                ptr `plusPtr` (location * stride) `poke` value
              |
                (location, value) <- IM.toList updates
              ]
        )
        $ hPrint stderr
      bindBuffer ArrayBuffer $=! Nothing


expandBuffer :: Show a => Storable a
             => a
             -> Int
             -> Int
             -> BufferObject
             -> IO BufferObject
expandBuffer exemplar oldSize newSize oldBufferObject =
  do
    let
      stride = sizeOf exemplar
    bindBuffer ArrayBuffer $=! Just oldBufferObject
    oldValues <- newArray (0, oldSize) exemplar
    touchStorableArray oldValues
    withStorableArray oldValues
      $ bufferSubData ArrayBuffer ReadFromBuffer 0 (fromIntegral $ oldSize * stride)
    newValues <- getElems oldValues >>= newListArray (0, newSize) . (++ repeat exemplar)
    deleteObjectName oldBufferObject
    newBufferObject <- genObjectName
    bindBuffer ArrayBuffer $=! Just newBufferObject
    withStorableArray newValues
      $ \ptr ->
        bufferData ArrayBuffer $=! (fromIntegral $ newSize * stride, ptr, DynamicDraw)
    bindBuffer ArrayBuffer $=! Nothing
    return newBufferObject
