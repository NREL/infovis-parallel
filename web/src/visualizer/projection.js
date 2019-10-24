
require("../gl-matrix")


const mat4 = glMatrix.mat4
const vec3 = glMatrix.vec3


function projectionKooimaOffAxis(display, eye) {

  const near       = display.nearPlane
  const far        = display.farPlane
  const lowerLeft  = display.lowerLeft
  const lowerRight = display.lowerRight
  const upperLeft  = display.upperLeft

  // Orthonormal basis for screen.
  const vr = vec3.normalize(vec3.create(), vec3.scaleAndAdd(vec3.create(), lowerRight, lowerLeft, -1))
  const vu = vec3.normalize(vec3.create(), vec3.scaleAndAdd(vec3.create(), upperLeft , lowerLeft, -1))
  const vn = vec3.normalize(vec3.create(), vec3.cross(vec3.create(), vr, vu))

  // Screen corners relative to eye.
  const va = vec3.scaleAndAdd(vec3.create(), lowerLeft , eye, -1)
  const vb = vec3.scaleAndAdd(vec3.create(), lowerRight, eye, -1)
  const vc = vec3.scaleAndAdd(vec3.create(), upperLeft , eye, -1)

  // Distancefrom eye to screen.
  const throw1 = - vec3.dot(va, vn)

  // Extent on near clipping plane.
  const scaling = near / throw1
  const left   = vec3.dot(vr, va) * scaling
  const right  = vec3.dot(vr, vb) * scaling
  const bottom = vec3.dot(vu, va) * scaling
  const top    = vec3.dot(vu, vc) * scaling

  // Matrix transforming world to screen.
  const m = mat4.fromValues(
    vr[0], vr[1], vr[2], 0
  , vu[0], vu[1], vu[2], 0
  , vn[0], vn[1], vn[2], 0
  ,     0,     0,     0, 1
  )

  // Frustum matrix.
  const frustum = mat4.fromValues(
    2 * near / (right - left),                         0,   (right + left  ) / (right - left  ),                               0
  ,                         0, 2 * near / (top - bottom),   (top   + bottom) / (top   - bottom),                               0
  ,                         0,                         0, - (far   + near  ) / (far   - near  ), - 2 * far * near / (far - near)
  ,                         0,                         0,                                    -1,                               0
  )

  // Translation matrix.
  const translate = mat4.fromValues(
    1, 0, 0, eye[0]
  , 0, 1, 0, eye[1]
  , 0, 0, 1, eye[2]
  , 0, 0, 0,      1
  )

  return mat4.multiply(mat4.create(), frustum, mat4.multiply(mat4.create(), m, translate))

}


module.exports = {
  projection      : projectionKooimaOffAxis
}
