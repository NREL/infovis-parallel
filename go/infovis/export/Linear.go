package export


import (
  "math"
)


const epsilon = 0.000001


var zero = [3]float32{0, 0, 0}


var basis = [][3]float32{
  {1, 0, 0},
  {0, 1, 0},
  {0, 0, 1},
}


func length(u [3]float32) float32 {
  return float32(math.Sqrt(float64(u[0] * u[0] + u[1] * u[1] + u[2]* u[2])))
}


func normalize(u [3]float32) [3]float32 {
  ul := length(u)
  if ul <= 0 {
    return zero
  }
  return [3]float32{u[0] / ul, u[1] / ul, u[2] / ul}
}


func orthogonal(v [3]float32) [3]float32 {
  var result [3]float32
  for _, e :=  range basis {
    u := cross(v, e)
    if !equals(u, zero) {
      result = u
    }
  }
  return result
}


func equals(u [3]float32, v [3]float32) bool {
  u0 := float64(u[0])
  u1 := float64(u[1])
  u2 := float64(u[2])
  v0 := float64(v[0])
  v1 := float64(v[1])
  v2 := float64(v[2])
  return math.Abs(u0 - v0) <= epsilon * math.Max(1, math.Max(u0, v0)) &&
         math.Abs(u1 - v1) <= epsilon * math.Max(1, math.Max(u1, v1)) &&
         math.Abs(u2 - v2) <= epsilon * math.Max(1, math.Max(u2, v2))
}

func add(u [3]float32, v [3]float32) [3]float32 {
  return [3]float32{
    u[0] + v[0],
    u[1] + v[1],
    u[2] + v[2],
  }
}


func scaleAndAdd(u [3]float32, v [3]float32, s float32) [3]float32 {
  return [3]float32{
    u[0] + v[0] * s,
    u[1] + v[1] * s,
    u[2] + v[2] * s,
  }
}


func dot(u [3]float32, v [3]float32) float32 {
  return u[0] * v[0] + u[1] * v[1] + u[2] * v[2]
}


func cross(u [3]float32, v [3]float32) [3]float32 {
  return [3]float32{
    u[1] * v[2] - u[2] * v[1],
    u[2] * v[0] - u[0] * v[2],
    u[0] * v[1] - u[1] * v[0],
  }
}


var qzero = [4]float32{0, 0, 0, 0}


func quatFromPair(u [3]float32, s float32) [4] float32 {
  return [4]float32{u[0], u[1], u[2], s}
}


func qlength(u [4]float32) float32 {
  return float32(math.Sqrt(float64(u[0] * u[0] + u[1] * u[1] + u[2]* u[2] + u[3] * u[3])))
}


func qnormalize(u [4]float32) [4]float32 {
  ul := qlength(u)
  if ul <= 0 {
    return qzero
  }
  return [4]float32{u[0] / ul, u[1] / ul, u[2] / ul, u[3] / ul}
}


func conjugate(a [4]float32) [4]float32 {
  return [4]float32{
    -a[0],
    -a[1],
    -a[2],
     a[3],
  }
}


func multiply(a [4]float32, b [4]float32) [4]float32 {
  ax := a[0]
  ay := a[1]
  az := a[2]
  aw := a[3]
  bx := b[0]
  by := b[1]
  bz := b[2]
  bw := b[3]
  return [4]float32{
    ax * bw + aw * bx + ay * bz - az * by,
    ay * bw + aw * by + az * bx - ax * bz,
    az * bw + aw * bz + ax * by - ay * bx,
    aw * bw - ax * bx - ay * by - az * bz,
  }
}


func transformQuat(a [3]float32, q [4]float32) [3]float32 {
  qx := q[0]
  qy := q[1]
  qz := q[2]
  qw := q[3]
  x := a[0]
  y := a[1]
  z := a[2]
  uvx := qy * z - qz * y
  uvy := qz * x - qx * z
  uvz := qx * y - qy * x
  uuvx := qy * uvz - qz * uvy
  uuvy := qz * uvx - qx * uvz
  uuvz := qx * uvy - qy * uvx
  w2 := qw * 2
  uvx *= w2
  uvy *= w2
  uvz *= w2
  uuvx *= 2
  uuvy *= 2
  uuvz *= 2
  return [3]float32{
    x + uvx + uuvx,
    y + uvy + uuvy,
    z + uvz + uuvz,
  }
}


func projectPlane(v [3]float32, u [3]float32) [3]float32 {
  un := normalize(u)
  return scaleAndAdd(v, un, - dot(v, un))
}


func rotationFromVectorPair(v1 [3]float32, v2 [3]float32) [4]float32 {
  v1n := normalize(v1)
  v2n := normalize(v2)
  v12 := add(v1n, v2n)
  v12n := normalize(v12)
  q := quatFromPair(cross(v12n, v2n), dot(v12n, v2n))
  if equals(v12, zero) {
    return quatFromPair(orthogonal(v1n), 0)
  }
  return q
}


func rotationFromPlane(xAxis [3]float32, yAxis [3]float32, origin [3]float32, xPoint [3]float32, yPoint [3]float32) [4]float32 {
  return rotationFromVectorPairs(xAxis, yAxis, scaleAndAdd(xPoint, origin, -1), scaleAndAdd(yPoint, origin, -1))
}


func rotationFromVectorPairs(u0 [3]float32, v0 [3]float32, u2 [3]float32, v2 [3]float32) [4]float32 {
  q2 := rotationFromVectorPair(u0, u2)
  v1 := transformQuat(v2, conjugate(q2))
  v0p := normalize(projectPlane(v0, u0))
  v1p := normalize(projectPlane(v1, u0))
  var q1 [4]float32
  if equals(add(v0p, v1p), zero) {
    q1 = quatFromPair(normalize(u0), 0)
  } else {
    q1 = rotationFromVectorPair(v0p, v1p)
  }
  return qnormalize(multiply(q2, q1))
}
