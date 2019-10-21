
require("../gl-matrix")

const Buffers  = require("./buffers"   )
const Shapes   = require("./shapes"    )


const quat = glMatrix.quat
const vec3 = glMatrix.vec3


function createSelector(gl, shapeProgram) {
  const shapeBuffer = Buffers.createShapeBuffer(gl, shapeProgram, gl.TRIANGLES, Shapes.cone(1, 1))
  Buffers.insertPositions(1, [vec3.fromValues(0, 0, 0)         ], shapeBuffer)
  Buffers.updateRotations(1, [quat.fromValues(0, 0, 0, 1)      ], shapeBuffer) // FIXME: This differs from the Haskell version, which might be incorrect.
  Buffers.updateScales   (1, [vec3.fromValues(0.05, 0.05, 0.05)], shapeBuffer)
  Buffers.updateColor    (1, 0xFF99007F                 , shapeBuffer)
  return shapeBuffer
}


function prepareSelector(gl, positionRotation, shapeBuffer) {
  const [[px, py, pz], [rw, rx, ry, rz]] = positionRotation // FIXME: Check ordering.
  Buffers.updatePositions(1, [vec3.fromValues(px, py, pz)    ], shapeBuffer)
  Buffers.updateRotations(1, [quat.fromValues(rx, ry, rz, rw)], shapeBuffer)
  Buffers.prepareShapeBuffer(gl, shapeBuffer)
}


function drawSelector(gl, shapeBuffer) {
  Buffers.drawInstances(gl, shapeBuffer)
}


module.exports = {
  createSelector  : createSelector
, prepareSelector : prepareSelector
, drawSelector    : drawSelector
}
