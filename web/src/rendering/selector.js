
const GlMatrix = require("../gl-matrix")

const Buffers  = require("./buffers"   )
const Shapes   = require("./shapes"    )


const Vector3 = GlMatrix.vec3.fromValues
const Vector4 = GlMatrix.vec4.fromValues
const Vertex3 = GlMatrix.vec3.fromValues


function createSelector(gl, shapeProgram) {
  var shapeBuffer = Buffers.createShapeBuffer(gl, shapeProgram, gl.TRIANGLES, Shapes.cone(1, 1))
  Buffers.insertPositions(1, [Vertex3(0, 0, 0)         ], shapeBuffer)
  Buffers.updateRotations(1, [Vector4(1, 0, 0, 0)      ], shapeBuffer)
  Buffers.updateScales   (1, [Vector3(0.05, 0.05, 0.05)], shapeBuffer)
  Buffers.updateColor    (1, 0xFF99007F                 , shapeBuffer)
  return shapeBuffer
}


function prepareSelector(gl, positionRotation, shapeBuffer) {
  var [[px, py, pz], [rw, rx, ry, rz]] = positionRotation // FIXME: Check ordering.
  Buffers.updatePositions(1, [Vertex3(px, py, pz)    ], shapeBuffer)
  Buffers.updateRotations(1, [Vector4(rx, ry, rz, rw)], shapeBuffer)
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
