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


func quatFromPair(u [3]float32, s float32) [4] float32 {
  return [4]float32{u[0], u[1], u[2], s}
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

