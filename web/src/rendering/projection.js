
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
  const frustum = mat4.frustum(mat4.create(), left, right, bottom, top, near, far)

  // Translation matrix.
  const translate = mat4.translate(mat4.create(), mat4.create(), eye)

//  near       =   1.0e-2
//  far        = 100.0
//  lowerLeft  =  -0.94 - 0.32   0.0
//  lowerRight =   1.94 - 0.32   0.0
//  upperLeft  =  -0.94   1.32   0.0
//  eye        =   3.0    2.0   10.0
//  vr         =   1.0    0.0    0.0
//  vu         =   0.0    1.0    0.0
//  vn         =   0.0    0.0    1.0
//  va         =  -3.94 -2.32  -10.0
//  vb         =  -1.06 -2.32  -10.0
//  vc         =  -3.94 -0.68  -10.0
//  throw      =  10.0
//  scale      =   1.0e-3
//  left       =  -3.94e-3
//  right      =  -1.06e-3
//  bottom     =  -2.32e-3
//  top        =  -6.8e-4
//  m          = 1.0                0.0                0.0                 0.0
//               0.0                1.0                0.0                 0.0
//               0.0                0.0                1.0                 0.0
//               0.0                0.0                0.0                 1.0
//  result     = 6.944444179534912  0.0               -1.7361111640930176 -3.4722213745117188
//               0.0               12.195122718811035 -1.829268455505371  -6.097560882568359
//               0.0                0.0               -1.0002000331878662  9.981998443603516
//               0.0               0.0                -1.0                 10.0

  const result =  mat4.multiply(mat4.create(), frustum, mat4.multiply(mat4.create(), m, translate))

  return mat4.transpose(mat4.create(), result)

}


function modelView(offsetPosition, offsetRotation) {
  return mat4.fromRotationTranslation(mat4.create(), offsetRotation, offsetPosition)
}


module.exports = {
  projection      : projectionKooimaOffAxis
, modelView       : modelView
}
