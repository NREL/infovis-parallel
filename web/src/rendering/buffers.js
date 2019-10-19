const GlMatrix = require("../gl-matrix")


const Vector3 = GlMatrix.vec3.fromValues

const Vector4 = GlMatrix.veck.fromValues

const Vertex3 = GlMatrix.vec3.fromValues


const zeroPosition = Vertex3(0, 0, 0)

const zeroRotation = Vector4(0, 0, 0, 1)

const zeroScale = Vector3(0, 0, 0)

const zeroColor = 0


const positionsLens = {
  get : (shapeBuffer                  ) => shapeBuffer.pendingPositions
, set : (shapeBuffer, pendingPositions) => shapeBuffer.pendingPositions = pendingPositions)
}


const rotationsLens = {
  get : (shapeBuffer                  ) => shapeBuffer.pendingRotations
, set : (shapeBuffer, pendingRotations) => shapeBuffer.pendingRotations = pendingRotations)
}


const scalesLens = {
  get : (shapeBuffer               ) => shapeBuffer.pendingScales
, set : (shapeBuffer, pendingScales) => shapeBuffer.pendingScales = pendingScales)
}


const colorsLens = {
  get : (shapeBuffer               ) => shapeBuffer.pendingColors
, set : (shapeBuffer, pendingColors) => shapeBuffer.pendingColors = pendingColors)
}


function hasIdentifier(shapeBuffer, identifier) {
  return (identifier in shapeBuffer.locationses)
}


function createShapeBuffer(gl, shapeProgram, primitiveMode, primitives) {
  return {
    shapeProgram     : shapeProgram
  , primitiveMode    : primitiveMode
  , mesh             : {left : gl1 => buildBuffer(gl1, primitives)}
  , vertexCount      : primitives.length
  , instanceCount    : 0
  , positions        : null
  , rotations        : null
  , scales           : null
  , colors           : null
  , size             : 0
  , empties          : new Set()
  , locationses      : {}
  , pendingPositions : {}
  , pendingRotations : {}
  , pendingScales    : {}
  , pendingColors    : {}
  , pendingSize      : 0
  }
}


function destroyShapeBuffer(gl, shapeBuffer) {
  if (shapeBuffer.size == 0)
    return
  deleteObjecttNames([shapeBuffer.positions, shapeBuffer.rotations, shapeBuffer.scales, shapeBuffer.colors])
  if ("right" in shapeBuffer.mesh)
    deleteObjectNames([shapeBuffer.mesh.right])
}



function insertPositions(identifier, positions, shapeBuffer) {
  positions.map(position => insertPosition(shapeBuffer, identifier, position))
}


function insertPosition(shapeBuffer, identifier, vertex) {

  var empties1 = shapeBuffer.empties
  var pendindSize1 = shapeBuffer.pendingSize
  if (empties1.length == 0) {
    empties1 = Array.from({length: pendingSize % 2 + 1}, (v, k) => pendingSize1 + k)
    pendingSize1 = pendingSize1 + empties1.length
  }

  var location = null
  empties1.forEach(function(x) {location = Math.min(location, x)})
  empties1.delete(location)

  shapeBuffer.empties = empties1
  shapeBuffer.pendingSize = pendingSize1
  shapeBuffer.pendingPositions[location] = vertex
  if (!(identifier in shapeBuffer.locationses))
    shapeBuffer.locationses[identifier] = new Set()
  shapeBuffer.locationses[identifier].add(location)

}


function updatePositions(identifier, positions, shapeBuffer) {
  updateAttributes(positionsLens, identifier, positions, shapeBuffer)
}


function updateRotations(identifier, rotations, shapeBuffer) {
  updateAttributes(rotationsLens, identifier, rotations, shapeBuffer)
}


function updateScales(identifier, scales, shapeBuffer) {
  updateAttributes(scalesLens, identifier, scales, shapeBuffer)
}
 

function updateAttributes(field, identifier, values, shapeBuffer) {
  if (identifier in shapeBuffer.locationses) {
    var locations = shapeBuffer.locationses[identifier]
    var revision = field.get(shapeBuffer)
    for (var i = 0; i <= Math.min(locations.length, values.length); ++i)
      revisions[locations[i]] = values[i]
    field.set(shapeBuffer, revision)
  }
}


function updateColor(identifier, color, shapeBuffer) {
  updateAttribute(colorLens, identifier, color, shapeBuffer)
}


function updateAttribute(field, identifier, value shapeBuffer) {
  if (identifier in shapeBuffer.locationses) {
    var locations = shapeBuffer.locationses[identifier]
    var revision = field.get(shapeBuffer)
    for (var i = 0; i <= locations.length; ++i)
      revisions[locations[i]] = value
    field.set(shapeBuffer, revision)
  }
}


function deleteInstance(shapeBuffer, identifier) {
  if (identifier in shapeBuffer.locationses) {
    var locations = shapeBuffer.locationses
    locations.forEach(function(location) {
      shapeBuffer.empties.add(location)
      shapeBuffer.pendingScales[location] = zeroScale
    })
    delete shapeBuffer.locationses[identifier]
  } 
}

  
function prepareShapeBuffer(gl, shapeBuffer) {
  expandShapeBuffer(gl, shapeBuffer)
  updateShapeBuffer(gl, shapeBuffer)
}


function updateShapeBuffer(gl, shapeBuffer) {

  if (shapeBuffer.pendingPositions.length +
      shapeBuffer.pendingRotations.length +
      shapeBuffer.pendingScales.length    +
      shapeBuffer.pendingColors           == 0)
    return

  updateBuffer(gl, shapeBuffer.pendingPositions, shapeBuffer.positions)
  updateBuffer(gl, shapeBuffer.pendingRotations, shapeBuffer.rotations)
  updateBuffer(gl, shapeBuffer.pendingScales   , shapeBuffer.scales   )
  updateBuffer(gl, shapeBuffer.pendingColors   , shapeBuffer.colors   )

  var location = null
  Object.values(shapeBuffer.locationses).forEach(xs =>
    xs.forEach(
      function(x) {
        location = Math.max(location, x)
      }
    )
  )

  shapeBuffer.instanceCount    = location + 1
  shapeBuffer.pendingPositions = {}
  shapeBuffer.pendingRotations = {}
  shapeBuffer.pendingScales    = {}
  shapeBuffer.pendingColors    = {}

}


function expandShapeBuffer(gl, shapeBuffer) {

  var size        = shapeBuffer.size
  var pendingSize = shapeBuffer.pendingSize

  if (pendingSize <= size)
    return

  function replicate(value) {
    return Array.from({length: pendingSize}, (v, k) => value)
  }

  if ("left" in shapeBuffer.mesh)
    shapeBuffer.mesh = shapeBuffer.mesh.left(gl)

  shapeBuffer.positions = size == 0 ? buildBuffer(gl, replicate(zeroPosition)) ? expandBuffer(gl, zeroPosition, size, pendingSize, shapeBuffer.positions)
  shapeBuffer.rotations = size == 0 ? buildBuffer(gl, replicate(zeroRotation)) ? expandBuffer(gl, zeroRotation, size, pendingSize, shapeBuffer.rotations)
  shapeBuffer.scales    = size == 0 ? buildBuffer(gl, replicate(zeroScale   )) ? expandBuffer(gl, zeroScale   , size, pendingSize, shapeBuffer.scales   )
  shapeBuffer.colors    = size == 0 ? buildBuffer(gl, replicate(zeroColor   )) ? expandBuffer(gl, zeroColor   , size, pendingSize, shapeBuffer.colors   )

}


function drawInstances(gl, shapeBuffer) {

  if (shapeBuffer.size == 0)
    return

  shapeProgram = shapeBuffer.shapeProgram

  selectShapeProgram(gl, shapeProgram)

//FIXME: SYnc projection model view.

  bindMesh     (gl, shapeProgram, shapeBuffer.mesh.right)
  bindPositions(gl, shapeProgram, shapeBuffer.positions )
  bindRotations(gl, shapeProgram, shapeBuffer.rotations )
  bindScales   (gl, shapeProgram, shapeBuffer.scales    )
  bindColors   (gl, shapeProgram, shapeBuffer.colors    )

  ext = gl.getExtension("ANGLE_instanced_arrays")
  ext.drawArraysInstances(shapeBuffer.primitiveMode, 0, shapeBuffer.vertexCount, shapeBuffer.instanceCount)

  // FIXME: Is this necessary?
  selectShapeProgram(gl, null)

}


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
        $ fail . show
      bindBuffer ArrayBuffer $=! Nothing


expandBuffer :: Storable a
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


module.exports = {
  createShapeBuffer  : createShapeBuffer
, prepareShapeBuffer : prepareShapeBuffer
, destroyShapeBuffer : destroyShapeBuffer
, hasIdentifier      : hasIdentifier
, insertPositions    : insertPositions
, updatePositions    : updatePositions
, updateRotations    : updateRotations
, updateScales       : updateScales
, updateColor        : updateColor
, deleteInstance     : deleteInstance
, drawInstances      : drawInstances
}
