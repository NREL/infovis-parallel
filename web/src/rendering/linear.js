
const mat3 = glMatrix.mat4
const quat = glMatrix.quat
const vec3 = glMatrix.vec3


function quatFromPair(v, s) {
  return quat.fromValues(v[0], v[1], v[2], s)
}


const zero = vec3.create()


const basis = [
  vec3.fromValues(1, 0, 0)
, vec3.fromValues(0, 1, 0)
, vec3.fromValues(0, 0, 1)
]


export function rotationFromVectorPair(v1, v2) {
  const v1n = vec3.normalize(vec3.create(), v1)
  const v2n = vec3.normalize(vec3.create(), v2)
  const v12 = vec3.add(vec3.create(), v1n, v2n)
  const v12n = vec3.normalize(vec3.create(), v12)
  const q = quatFromPair(vec3.cross(vec3.create(), v12n, v2n), vec3.dot(v12n, v2n))
  if (vec3.equals(v12, zero))
    return quatFromPair(orthogonal(v1n), 0)
  return q
}


export function orthogonal(v) {
  let result = null
  basis.forEach(function(e) {
    const u = vec3.cross(vec3.create(), v, e)
    if (!vec3.equals(u, zero))
      result = u
  })
  return result
}


export function projectPlane(v, u) {
  const un = vec3.normalize(vec3.create(), u)
  return vec3.scaleAndAdd(vec3.create(), v, un, - vec3.dot(v, un))
}


export function rotationFromVectorPairs(u0, v0, u2, v2) {
  const q2 = rotationFromVectorPair(u0, u2)
  const v1 = vec3.transformQuat(vec3.create(), v2, quat.conjugate(quat.create(), q2))
  const v0p = vec3.normalize(vec3.create(), projectPlane(v0, u0))
  const v1p = vec3.normalize(vec3.create(), projectPlane(v1, u0))
  const q1 = vec3.equals(vec3.add(vec3.create(), v0p, v1p), zero) ? quatFromPair(vec3.normalize(vec3.create(), u0), 0) : rotationFromVectorPair(v0p, v1p)
  return quat.normalize(quat.create(), quat.multiply(quat.create(), q2, q1))
}


export function rotationFromPlane(xAxis, yAxis, origin, xPoint, yPoint) {
  return rotationFromVectorPairs(
    xAxis
  , yAxis
  , vec3.scaleAndAdd(vec3.create(), xPoint, origin, -1)
  , vec3.scaleAndAdd(vec3.create(), yPoint, origin, -1)
  )
}


export function fromEulerd(v) {
  return quat.fromEuler(quat.create(), v[0], v[1], v[2])
}


export function fromEuler(v) {
  return fromEuler(vec3.scale(vec3.create(), v, 180 / Math.PI))
}


export function toEuler(q) {
  const x = q[0]
  const y = q[1]
  const z = q[2]
  const w = q[3]
  const phi = Math.atan2(2 * (w * x  + y * z), 1 - 2 * (x * x + y * y))
  const theta = Math.asin(Math.max(-1, Math.min(1, 2 * (w * y - z * x))))
  const psi = Math.atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z))
  return vec3.fromValues(phi, theta, psi)
}


export function toEulerd(q) {
  return vec3.scale(vec3.create(), toEuler(q), 180 / Math.PI)
}


export function distanceToPoint(po, ps) {
  return vec3.distance(po, ps)
}


export function distanceToSegment(po, pu, ps) {
  const [abg, uvw] = boxCoordinates(po, pu, null, null, ps)
  return vec3.length(distanceOnSegment(uvw, abg))
}


export function distanceToRectangle(po, pu, pv, ps) {
  const [abg, uvw] = boxCoordinates(po, pu, pv, null, ps)
  return vec3.length(distanceOnSegment(uvw, abg))
}


export function distanceToBox(po, pu, pv, pw, ps) {
  const [abg, uvw] = boxCoordinates(po, pu, pv, pw, ps)
  return vec3.length(distanceOnSegment(uvw, abg))
}


export function distanceOnSegment(un, alpha) {
  if (alpha <= 0)
    return - alpha
  if (alpha >= un)
    return alpha - un
  return 0
}


export function boxCoordinates(po, pu, pv, pw, ps) {
  const s = vec3.scaleAndAdd(vec3.create(), ps, po, -1)
  const u = vec3.scaleAndAdd(vec3.create(), pu, po, -1)
  let e = basis[0]
  basis.forEach(function(e1) {
    if (!glMatrix.equals(vec3.dot(u, e1), 0))
      e = e1
  })
  const v = pv == null ? vec3.cross(vec3.create(), u, e) : vec3.scaleAndAdd(vec3.create(), pv, po, -1)
  const w = pw == null ? vec3.cross(vec3.create(), u, v) : vec3.scaleAndAdd(vec3.create(), pw, po, -1)
  const uh = vec3.normalize(vec3.create(), u)
  const vh = vec3.normalize(vec3.create(), v)
  const wh = vec3.normalize(vec3.create(), w)
  const uv = vec3.dot(uh, vh)
  const wu = vec3.dot(wh, uh)
  const vw = vec3.dot(vh, wh)
  const mi = mat3.invert(mat3.create(), mat3.fromValues(1, uv, wu, uv, 1, vw, wu, vw, 1))
  return [
    vec3.transformMat3(
      vec3.create()
    , vec3.fromValues(
        vec3.dot(s, uh)
      , vec3.dot(s, vh)
      , vec3.dot(s, wh)
      )
    , mi
    )
  , vec3.fromValues(
      vec3.length(u)
    , pv == null ? 0 : vec3.length(v)
    , pw == null ? 0 : vec3.length(w)
    )
  ]
}


export function toQuaternion(w, x, y, z) {
  return quat.fromValues(x, y, z, w)
}
