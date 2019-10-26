
const Program = require("./program")

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
  return shapeBuffer.locationses.has(identifier)
}


function createShapeBuffer(gl, shapeProgram, primitiveMode, primitives) {
  return {
    shapeProgram     : shapeProgram
  , primitiveMode    : primitiveMode
  , mesh             : buildBuffer(gl, primitives, shapeProgram.meshDescription)
  , vertexCount      : primitives.length
  , instanceCount    : 0
  , positions        : null
  , rotations        : null
  , scales           : null
  , colors           : null
  , size             : 0
  , empties          : new Set()
  , locationses      : new Map()
  , pendingPositions : new Map()
  , pendingRotations : new Map()
  , pendingScales    : new Map()
  , pendingColors    : new Map()
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
  positions.map((position) => insertPosition(shapeBuffer, identifier, position))
}


function insertPosition(shapeBuffer, identifier, vertex) {

  let empties1 = shapeBuffer.empties
  let pendingSize1 = shapeBuffer.pendingSize
  if (empties1.size == 0) {
    empties1 = new Set(Array.from({length: shapeBuffer.pendingSize % 2 + 1}, (v, k) => pendingSize1 + k))
    pendingSize1 = pendingSize1 + empties1.size
  }

  let location = null
  empties1.forEach(function(x) {location = location == null ? x : Math.min(location, x)})
  empties1.delete(location)

  console.debug("insertPosition: identifier =", identifier, ", vertex =", vertex)
  console.debug("insertPosition: location = ", location, ", pendingSize1 =", pendingSize1, ", empties1 =", empties1)
  shapeBuffer.empties = empties1
  shapeBuffer.pendingSize = pendingSize1
  shapeBuffer.pendingPositions.set(location, vertex)
  if (!shapeBuffer.locationses.has(identifier))
    shapeBuffer.locationses.set(identifier, new Set())
  shapeBuffer.locationses.get(identifier).add(location)

}


function updatePositions(identifier, positions, shapeBuffer) {
  console.debug("updatePositions: identifier =", identifier, ", positions =", positions)
  updateAttributes(positionsLens, identifier, positions, shapeBuffer)
}


function updateRotations(identifier, rotations, shapeBuffer) {
  console.debug("updateRotations: identifier =", identifier, ", rotations =", rotations)
  updateAttributes(rotationsLens, identifier, rotations, shapeBuffer)
}


function updateScales(identifier, scales, shapeBuffer) {
  console.debug("updateScales: identifier =", identifier, ", scales =", scales)
  updateAttributes(scalesLens, identifier, scales, shapeBuffer)
}


function updateAttributes(field, identifier, values, shapeBuffer) {
  if (shapeBuffer.locationses.has(identifier)) {
    const locations = shapeBuffer.locationses.get(identifier)
    const revisions = field.get(shapeBuffer)
    let i = 0
    locations.forEach((location) => revisions.set(location, values[i++]))
    field.set(shapeBuffer, revisions)
  }
}


function updateColor(identifier, color, shapeBuffer) {
  console.debug("updateColor: identifier =", identifier, ", color =", color)
  updateAttribute(colorsLens, identifier, color, shapeBuffer)
}


function updateAttribute(field, identifier, value, shapeBuffer) {
  if (shapeBuffer.locationses.has(identifier)) {
    const locations = shapeBuffer.locationses.get(identifier)
    const revisions = field.get(shapeBuffer)
    locations.forEach((location) => revisions.set(location, value))
    field.set(shapeBuffer, revisions)
  }
}


function deleteInstance(shapeBuffer, identifier) {
  if (shapeBuffer.locationses.has(identifier)) {
    const locations = shapeBuffer.locationses
    locations.forEach(function(location) {
      shapeBuffer.empties.add(location)
      shapeBuffer.pendingScales.set(location, zeroScale)
    })
    shapeBuffer.locationses.delete(identifier)
  }
}


function prepareShapeBuffer(gl, shapeBuffer) {
  console.debug("prepareShapeBuffer")
  expandShapeBuffer(gl, shapeBuffer)
  updateShapeBuffer(gl, shapeBuffer)
}


function updateShapeBuffer(gl, shapeBuffer) {

  if (shapeBuffer.pendingPositions.size +
      shapeBuffer.pendingRotations.size +
      shapeBuffer.pendingScales.size    +
      shapeBuffer.pendingColors     == 0)
    return

  console.debug("updateShapeBuffer")

  updateBuffer(gl, shapeBuffer.pendingPositions, shapeBuffer.positions, shapeBuffer.shapeProgram.positionsDescription)
  updateBuffer(gl, shapeBuffer.pendingRotations, shapeBuffer.rotations, shapeBuffer.shapeProgram.rotationsDescription)
  updateBuffer(gl, shapeBuffer.pendingScales   , shapeBuffer.scales   , shapeBuffer.shapeProgram.scalesDescription   )
  updateBuffer(gl, shapeBuffer.pendingColors   , shapeBuffer.colors   , shapeBuffer.shapeProgram.colorsDescription   )

  let location = null
  shapeBuffer.locationses.forEach((xs, _) =>
    xs.forEach(
      function(x) {
        location = Math.max(location, x)
      }
    )
  )

  shapeBuffer.instanceCount    = location + 1
  shapeBuffer.pendingPositions = new Map()
  shapeBuffer.pendingRotations = new Map()
  shapeBuffer.pendingScales    = new Map()
  shapeBuffer.pendingColors    = new Map()

}


function expandShapeBuffer(gl, shapeBuffer) {

  const size        = shapeBuffer.size
  const pendingSize = shapeBuffer.pendingSize

  if (pendingSize <= size)
    return

  function replicate(value) {
    return Array.from({length: pendingSize}, (v, k) => value)
  }

  console.debug("expandShapeBuffer: size =", size, ", pendingSize =", pendingSize)

  if (size == 0) {
    shapeBuffer.positions = buildBuffer(gl, replicate(zeroPosition), shapeBuffer.shapeProgram.positionsDescription)
    shapeBuffer.rotations = buildBuffer(gl, replicate(zeroRotation), shapeBuffer.shapeProgram.rotationsDescription)
    shapeBuffer.scales    = buildBuffer(gl, replicate(zeroScale   ), shapeBuffer.shapeProgram.scalesDescription   )
    shapeBuffer.colors    = buildBuffer(gl, replicate(zeroColor   ), shapeBuffer.shapeProgram.colorsDescription   )
  } else {
    shapeBuffer.positions = expandBuffer(gl, shapeBuffer.shapeProgram.positionsDescription, size, pendingSize, shapeBuffer.positions)
    shapeBuffer.rotations = expandBuffer(gl, shapeBuffer.shapeProgram.rotationsDescription, size, pendingSize, shapeBuffer.rotations)
    shapeBuffer.scales    = expandBuffer(gl, shapeBuffer.shapeProgram.scalesDescription   , size, pendingSize, shapeBuffer.scales   )
    shapeBuffer.colors    = expandBuffer(gl, shapeBuffer.shapeProgram.colorsDescription   , size, pendingSize, shapeBuffer.colors   )
  }

  shapeBuffer.size = pendingSize

}


function drawInstances(gl, shapeBuffer, projection, modelView) {

  if (shapeBuffer.size == 0)
    return

  console.debug("drawInstances: vertices =", shapeBuffer.vertexCount, ", instances =", shapeBuffer.instanceCount)

  const shapeProgram = shapeBuffer.shapeProgram

  Program.selectShapeProgram(gl, shapeProgram)

  Program.bindMesh     (gl, shapeProgram, shapeBuffer.mesh     )
  Program.bindPositions(gl, shapeProgram, shapeBuffer.positions)
  Program.bindRotations(gl, shapeProgram, shapeBuffer.rotations)
  Program.bindScales   (gl, shapeProgram, shapeBuffer.scales   )
  Program.bindColors   (gl, shapeProgram, shapeBuffer.colors   )

  Program.setProjectionModelView(gl, shapeProgram, projection, modelView)

  console.debug("drawInstances: gl.drawArraysInstanced")
  gl.drawArraysInstanced(shapeBuffer.primitiveMode, 0, shapeBuffer.vertexCount, shapeBuffer.instanceCount)

}


function buildBuffer(gl, primitives, description) {

  console.debug("buildBuffer: description = ", description, ", primitives ="  , primitives)

  const bufferObject = gl.createBuffer()

  gl.bindBuffer(gl.ARRAY_BUFFER, bufferObject)

  const components = description.components
  const bytes = description.isFloat                  ?
    new Float32Array(primitives.length * components) :
    new Uint32Array (primitives.length * components)
  if (components == 1)
    for (let i = 0; i < primitives.length; ++i)
      bytes[i] = primitives[i]
  else
    for (let i = 0; i < primitives.length; ++i)
      for (let j = 0; j < components; ++j)
        bytes[i * components + j] = primitives[i][j]
  gl.bufferData(gl.ARRAY_BUFFER, bytes, gl.DYNAMIC_DRAW)

  gl.bindBuffer(gl.ARRAY_BUFFER, null)

  return bufferObject
}


function updateBuffer(gl, updates, bufferObject, description) {

  console.debug("updateBuffer: description = ", description, ", updates ="     , updates)

  const components = description.components
  const bytes = description.isFloat ?
    new Float32Array(components)    :
    new Uint32Array (components)

  gl.bindBuffer(gl.ARRAY_BUFFER, bufferObject)

  updates.forEach(function(value, location) {
    if (components == 1)
      bytes[0] = value
    else
      for (let j = 0; j < components; ++j)
        bytes[j] = value[j]
    gl.bufferSubData(gl.ARRAY_BUFFER, components * location, bytes)
  })

  gl.bindBuffer(gl.ARRAY_BUFFER, null)

}


function expandBuffer(gl, description, oldSize, newSize, oldBufferObject) {

  console.debug("expandBuffer: description = ", description, ", oldSize =", oldSize, ", newSize =", newSize)

  const bytes = 4 // 32-bit elements.
  const components = description.components

  const newBufferObject = gl.createBuffer()
  gl.bindBuffer(gl.ARRAY_BUFFER, newBufferObject)
  gl.bufferData(newBufferObject, bytes * components * newSize, gl.DYNAMIC_DRAW)

  gl.bindBuffer(gl.COPY_READ_BUFFER, oldBufferObject)
  gl.copyBufferSubData(gl.COPY_READY_BUFFER, gl.ARRAY_BUFFER, 0, 0, bytes * components * oldSize)
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

, buildBuffer        : buildBuffer
}
