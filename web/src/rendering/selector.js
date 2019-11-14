
import * as Buffers from "./buffers"
import      Shapes  from "./shapes"


const quat = glMatrix.quat
const vec3 = glMatrix.vec3


const DEBUG = false


export function create(gl, shapeProgram) {
  if (DEBUG) console.debug("createSelector")
  const shapeBuffer = Buffers.createShapeBuffer(gl, shapeProgram, gl.TRIANGLES, Shapes.cone(1, 1))
  Buffers.insertPositions(1, [vec3.fromValues(0, 0, 0)         ], shapeBuffer)
  Buffers.updateRotations(1, [quat.fromValues(0, 0, 0, 1)      ], shapeBuffer) // FIXME: This differs from the Haskell version, which might be incorrect.
  Buffers.updateScales   (1, [vec3.fromValues(0.05, 0.05, 0.05)], shapeBuffer)
  Buffers.updateColor    (1, 0xFF99007F                         , shapeBuffer)
  return shapeBuffer
}


export function prepare(gl, shapeBuffer, position, rotation) {
  if (DEBUG) console.debug("prepareSelector: position =", position, ", rotation =", rotation)
  Buffers.updatePositions(1, [position], shapeBuffer)
  Buffers.updateRotations(1, [rotation], shapeBuffer)
  Buffers.prepareShapeBuffer(gl, shapeBuffer)
}


export function draw(gl, shapeBuffer, projection, modelView) {
  if (DEBUG) console.debug("drawSelector")
  Buffers.drawInstances(gl, shapeBuffer, projection, modelView)
}
