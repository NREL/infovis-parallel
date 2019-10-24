
require("../gl-matrix")


const zeroPosition = glMatrix.vec3.fromValues(0, 0, 0)

const zeroRotation = glMatrix.quat.fromValues(0, 0, 0, 1)

const zeroScale = glMatrix.vec3.fromValues(0, 0, 0)

const zeroColor = 0.0


const positionsLens = {
  get : (shapeBuffer                  ) => shapeBuffer.pendingPositions
, set : (shapeBuffer, pendingPositions) => shapeBuffer.pendingPositions = pendingPositions
}


const rotationsLens = {
  get : (shapeBuffer                  ) => shapeBuffer.pendingRotations
, set : (shapeBuffer, pendingRotations) => shapeBuffer.pendingRotations = pendingRotations
}


const scalesLens = {
  get : (shapeBuffer               ) => shapeBuffer.pendingScales
, set : (shapeBuffer, pendingScales) => shapeBuffer.pendingScales = pendingScales
}


const colorsLens = {
  get : (shapeBuffer               ) => shapeBuffer.pendingColors
, set : (shapeBuffer, pendingColors) => shapeBuffer.pendingColors = pendingColors
}


function hasIdentifier(shapeBuffer, identifier) {
  return (identifier in shapeBuffer.locationses)
}


function createShapeBuffer(gl, shapeProgram, primitiveMode, primitives) {
  return {
    shapeProgram     : shapeProgram
  , primitiveMode    : primitiveMode
  , mesh             : buildBuffer(gl, primitives)
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
  gl.deleteBuffer(shapeBuffer.mesh)
  if (shapeBuffer.size == 0)
    return
  [
    shapeBuffer.positions
  , shapeBuffer.rotations
  , shapeBuffer.scales
  , shapeBuffer.colors
  ].forEach(gl.deleteBuffer)
}



function insertPositions(identifier, positions, shapeBuffer) {
  positions.map(position => insertPosition(shapeBuffer, identifier, position))
}


function insertPosition(shapeBuffer, identifier, vertex) {

  let empties1 = shapeBuffer.empties
  let pendingSize1 = shapeBuffer.pendingSize
  if (empties1.length == 0) {
    empties1 = Array.from({length: pendingSize % 2 + 1}, (v, k) => pendingSize1 + k)
    pendingSize1 = pendingSize1 + empties1.length
  }

  let location = null
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
    const locations = shapeBuffer.locationses[identifier]
    const revision = field.get(shapeBuffer)
    for (let i = 0; i <= Math.min(locations.length, values.length); ++i)
      revisions[locations[i]] = values[i]
    field.set(shapeBuffer, revision)
  }
}


function updateColor(identifier, color, shapeBuffer) {
  updateAttribute(colorsLens, identifier, color, shapeBuffer)
}


function updateAttribute(field, identifier, value, shapeBuffer) {
  if (identifier in shapeBuffer.locationses) {
    const locations = shapeBuffer.locationses[identifier]
    const revision = field.get(shapeBuffer)
    for (let i = 0; i <= locations.length; ++i)
      revisions[locations[i]] = value
    field.set(shapeBuffer, revision)
  }
}


function deleteInstance(shapeBuffer, identifier) {
  if (identifier in shapeBuffer.locationses) {
    const locations = shapeBuffer.locationses
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

  let location = null
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

  const size        = shapeBuffer.size
  const pendingSize = shapeBuffer.pendingSize

  if (pendingSize <= size)
    return

  function replicate(value) {
    return Array.from({length: pendingSize}, (v, k) => value)
  }

  shapeBuffer.positions = size == 0                                          ?
    buildBuffer(gl, replicate(zeroPosition))                                 :
    expandBuffer(gl, zeroPosition, size, pendingSize, shapeBuffer.positions)
  shapeBuffer.rotations = size == 0                                          ?
    buildBuffer(gl, replicate(zeroRotation))                                 :
    expandBuffer(gl, zeroRotation, size, pendingSize, shapeBuffer.rotations)
  shapeBuffer.scales    = size == 0                                          ?
    buildBuffer(gl, replicate(zeroScale   ))                                 :
    expandBuffer(gl, zeroScale   , size, pendingSize, shapeBuffer.scales   )
  shapeBuffer.colors    = size == 0                                          ?
    buildBuffer(gl, replicate(zeroColor   ))                                 :
    expandBuffer(gl, zeroColor   , size, pendingSize, shapeBuffer.colors   )

}


function drawInstances(gl, shapeBuffer) {

  if (shapeBuffer.size == 0)
    return

  const shapeProgram = shapeBuffer.shapeProgram

  Program.selectShapeProgram(gl, shapeProgram)

//FIXME: SYnc projection model view.

  Program.bindMesh     (gl, shapeProgram, shapeBuffer.mesh.right)
  Program.bindPositions(gl, shapeProgram, shapeBuffer.positions )
  Program.bindRotations(gl, shapeProgram, shapeBuffer.rotations )
  Program.bindScales   (gl, shapeProgram, shapeBuffer.scales    )
  Program.bindColors   (gl, shapeProgram, shapeBuffer.colors    )

  gl.drawArraysInstanced(shapeBuffer.primitiveMode, 0, shapeBuffer.vertexCount, shapeBuffer.instanceCount)

  Program.selectShapeProgram(gl, null)

}


function buildBuffer(gl, primitives) {
  const bufferObject = gl.createBuffer()
  gl.bindBuffer(gl.ARRAY_BUFFER, bufferObject)
  gl.bufferData(gl.ARRAY_BUFFER, primitives, gl.DYNAMIC_DRAW)
  gl.bindBuffer(gl.ARRAY_BUFFER, null)
  return bufferObject
}


function updateBuffer(gl, updates, bufferObject) {
  gl.bindBuffer(gl.ARRAY_BUFFER, bufferObject)
  updates.forEach(function(location, value) {
    gl.bufferSubData(gl.ARRAY_BUFFER, stride * location, value)
  })
  gl.bindBuffer(gl.ARRAY_BUFFER, null)
}


function expandBuffer(gl, stride, oldSize, newSize, oldBufferObject) {

  const newBufferObject = gl.createBuffer()
  gl.bindBuffer(gl.ARRAY_BUFFER, newBufferObject)
  gl.bufferData(newBufferObject, stride * newSize, gl.DYNAMIC_DRAW)

  gl.bindBuffer(gl.COPY_READ_BUFFER, oldBufferObject)
  gl.copyBufferSubData(gl.COPY_READY_BUFFER, gl.ARRAY_BUFFER, 0, 0, stride * oldSize)
  gl.bindBuffer(gl.ARRAY_BUFFER, null)

  gl.bindBuffer(gl.COPY_READY_BUFFER, null)
  gl.deleteBuffer(oldBufferObject)

  return newBufferObject

}


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
