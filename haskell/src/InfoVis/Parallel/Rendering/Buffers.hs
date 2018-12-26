{-# LANGUAGE NamedFieldPuns  #-}
{-# LANGUAGE Rank2Types      #-}
{-# LANGUAGE RecordWildCards #-}


module InfoVis.Parallel.Rendering.Buffers (
  ShapeBuffer
, createShapeBuffer
, prepareShapeBuffer
, destroyShapeBuffer
, hasIdentifier
, insertPositions
, updatePositions
, updateRotations
, updateScale
, updateColor
, deleteInstances
, drawInstances
) where


import Control.Lens.Lens (Lens', lens)
import Control.Lens.Setter (over)
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
import qualified Data.Map.Strict as M (Map, (!), delete, empty, foldl, insertWith, member)
import qualified Data.IntSet as IS (IntSet, deleteFindMin, empty, findMax, foldl, fromList, null, singleton, toList, union)


type Position = Vertex3 GLfloat


zeroPosition :: Position
zeroPosition = Vertex3 0 0 0


type Rotation = Vector4 GLfloat


zeroRotation :: Rotation
zeroRotation = Vector4 0 0 0 0


type Scale = Vector3 GLfloat


zeroScale :: Scale
zeroScale = Vector3 0 0 0


type Color = GLuint


zeroColor :: Color
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
  , locationses      :: M.Map Identifier IS.IntSet
  , pendingPositions :: IM.IntMap Position
  , pendingRotations :: IM.IntMap Rotation
  , pendingScales    :: IM.IntMap Scale
  , pendingColors    :: IM.IntMap Color
  , pendingSize      :: Int
  }


positionsLens :: Lens' ShapeBuffer (IM.IntMap Position)
positionsLens = lens pendingPositions (\s pendingPositions -> s {pendingPositions})


rotationsLens :: Lens' ShapeBuffer (IM.IntMap Rotation)
rotationsLens = lens pendingRotations (\s pendingRotations -> s {pendingRotations})


scalesLens :: Lens' ShapeBuffer (IM.IntMap Scale)
scalesLens = lens pendingScales (\s pendingScales -> s {pendingScales})


colorsLens :: Lens' ShapeBuffer (IM.IntMap Color)
colorsLens = lens pendingColors (\s pendingColors -> s {pendingColors})


hasIdentifier :: ShapeBuffer
              -> Identifier
              -> Bool
hasIdentifier = flip M.member . locationses


createShapeBuffer :: Int
                  -> ShapeProgram
                  -> (PrimitiveMode, [Position])
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
      locationses = M.empty
      pendingPositions = IM.empty
      pendingRotations = IM.empty
      pendingScales    = IM.empty
      pendingColors    = IM.empty
      pendingSize = size
    return ShapeBuffer{..}


destroyShapeBuffer :: ShapeBuffer
                   -> IO ()
destroyShapeBuffer ShapeBuffer{..} = deleteObjectNames [mesh, positions, rotations, scales, colors]


insertPositions :: (Identifier, [Position])
                -> ShapeBuffer
                -> ShapeBuffer
insertPositions = flip $ (. uncurry ((<$>) . (,))) . foldl insertPosition


insertPosition :: ShapeBuffer
               -> (Identifier, Position)
               -> ShapeBuffer
insertPosition shapeBuffer@ShapeBuffer{..} (identifier, vertex) =
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
    , locationses      = M.insertWith IS.union identifier (IS.singleton location) locationses
    , pendingPositions = IM.insert location vertex pendingPositions
    , pendingSize      = pendingSize''
    }


updatePositions :: (Identifier, [Position])
                -> ShapeBuffer
                -> ShapeBuffer
updatePositions = updateAttributes positionsLens

  
updateRotations :: (Identifier, [Rotation])
               -> ShapeBuffer
               -> ShapeBuffer
updateRotations = updateAttributes rotationsLens
 

updateAttributes :: Lens' ShapeBuffer (IM.IntMap a)
                -> (Identifier, [a])
                -> ShapeBuffer
                -> ShapeBuffer
updateAttributes field (identifier, values) shapeBuffer@ShapeBuffer{..} =
  over
    field
    (
      IM.union
        $ IM.fromList (zip (IS.toList $ locationses M.! identifier) values)
    )
    shapeBuffer


updateScale :: (Identifier, Scale)
            -> ShapeBuffer
            -> ShapeBuffer
updateScale = updateAttribute scalesLens
 

updateColor :: (Identifier, Color)
            -> ShapeBuffer
            -> ShapeBuffer
updateColor = updateAttribute colorsLens
 

updateAttribute :: Lens' ShapeBuffer (IM.IntMap a)
                -> (Identifier, a)
                -> ShapeBuffer
                -> ShapeBuffer
updateAttribute field (identifier, value) shapeBuffer@ShapeBuffer{..} =
  over
    field
    (
      flip
        (IS.foldl (flip $ flip IM.insert value))
        $ locationses M.! identifier
    )
    shapeBuffer


deleteInstances :: ShapeBuffer
                -> [Identifier]
                -> ShapeBuffer
deleteInstances shapeBuffer@ShapeBuffer{..} identifiers =
  let
    locations = foldl (flip $ IS.union . (locationses M.!)) IS.empty identifiers
  in
    shapeBuffer
    {
      empties       = empties `IS.union` locations
    , locationses     = foldl (flip M.delete) locationses identifiers
    , pendingScales = IS.foldl (flip $ flip IM.insert zeroScale) pendingScales locations
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
               instanceCount    = fromIntegral $ IS.findMax (M.foldl IS.union (IS.singleton (-1)) locationses) + 1
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
