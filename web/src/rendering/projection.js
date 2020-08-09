
const mat4 = glMatrix.mat4
const vec3 = glMatrix.vec3


export function projection(display, eye) {

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
  const scaling = throw1 > 0 ? near / throw1 : 1e9
  const left   = vec3.dot(vr, va) * scaling
  const right  = vec3.dot(vr, vb) * scaling
  const bottom = vec3.dot(vu, va) * scaling
  const top    = vec3.dot(vu, vc) * scaling

  // Matrix transforming world to screen.
  const m = mat4.fromValues(vr[0], vu[0], vn[0], 0, vr[1], vu[1], vn[1], 0, vr[2], vu[2], vn[2], 0, 0, 0, 0, 1)

  // Frustum matrix.
  const frustum = mat4.frustum(mat4.create(), left, right, bottom, top, near, far)

  return mat4.translate(
    mat4.create()
  , mat4.multiply(mat4.create(), frustum, m)
  , vec3.scaleAndAdd(vec3.create(), vec3.create(), eye, -1)
  )

}


export function modelView(offsetPosition, offsetRotation) {
  return mat4.fromRotationTranslation(mat4.create(), offsetRotation, offsetPosition)
}
