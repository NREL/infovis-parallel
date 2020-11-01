package export


import (
  "math"
  "github.com/qmuntal/gltf"
  "github.com/qmuntal/gltf/modeler"
)


func box(doc *gltf.Document, x float32, y float32, z float32) [2]uint32 {
  var x1 = x / 2
  var y1 = y / 2
  var z1 = z / 2
  positionAccessor := modeler.WritePosition(doc, [][3]float32{
    { x1,  y1,  z1},
    { x1,  y1, -z1},
    { x1, -y1,  z1},
    { x1, -y1, -z1},
    {-x1,  y1,  z1},
    {-x1,  y1, -z1},
    {-x1, -y1,  z1},
    {-x1, -y1, -z1},
  })
  indicesAccessor := modeler.WriteIndices(doc, []uint8{
    0, 2, 3,  3, 1, 0,
    0, 1, 5,  5, 4, 0,
    0, 4, 6,  6, 2, 0,
    7, 3, 2,  2, 6, 7,
    7, 5, 1,  1, 3, 7,
    7, 6, 4,  4, 5, 7,
  })
  return [2]uint32{positionAccessor, indicesAccessor}
}


func cube(doc *gltf.Document, d float32) [2]uint32 {
  return box(doc, d, d, d)
}


func tube(doc *gltf.Document, l float32, d float32) [2]uint32 {
  var s = d / (1 + 2 * float32(math.Sqrt(2)))
  var u = s / 2
  var v = u + s * float32(math.Sqrt(2))
  var h = l / 2
  positionAccessor := modeler.WritePosition(doc, [][3]float32{
    {-h,  u,  v},
    {-h,  v,  u},
    {-h,  v, -u},
    {-h,  u, -v},
    {-h, -u, -v},
    {-h, -v, -u},
    {-h, -v,  u},
    {-h, -u,  v},
    { h,  u,  v},
    { h,  v,  u},
    { h,  v, -u},
    { h,  u, -v},
    { h, -u, -v},
    { h, -v, -u},
    { h, -v,  u},
    { h, -u,  v},
  })
  indicesAccessor := modeler.WriteIndices(doc, []uint8{
     0,  8,  9,   9,  1,  0,
     1,  9, 10,  10,  2,  1,
     2, 10, 11,  11,  3,  2,
     3, 11, 12,  12,  4,  3,
     4, 12, 13,  13,  5,  4,
     5, 13, 14,  14,  6,  5,
     6, 14, 15,  15,  7,  6,
     7, 15,  8,   8,  0,  7,
     0,  1,  6,   6,  7,  0,
     1,  2,  5,   5,  6,  1,
     2,  3,  4,   4,  5,  2,
    15, 14,  9,   9,  8, 15,
    14, 13, 10,  10,  9, 14,
    13, 12, 11,  11, 10, 13,
  })
  return [2]uint32{positionAccessor, indicesAccessor}
}


func icosahedron(doc *gltf.Document, d float32) [2]uint32 {
  var phi = (1 + math.Sqrt(5)) / 2
  var x = d / 2 / float32(math.Sqrt(1 + phi * phi))
  var z = float32(phi) * x
  const n = 0
  positionAccessor := modeler.WritePosition(doc, [][3]float32{
    {-x,  n,  z},
    { x,  n,  z},
    {-x,  n, -z},
    { x,  n, -z},
    { n,  z,  x},
    { n,  z, -x},
    { n, -z,  x},
    { n, -z, -x},
    { z,  x,  n},
    {-z,  x,  n},
    { z, -x,  n},
    {-z, -x,  n},
  })
  indicesAccessor := modeler.WriteIndices(doc, []uint8{
     0,  4,  1,
     0,  9,  4,
     9,  5,  4,
     4,  5,  8,
     4,  8,  1,
     8, 10,  1,
     8,  3, 10,
     5,  3,  8,
     5,  2,  3,
     2,  7,  3,
     7, 10,  3,
     7,  6, 10,
     7, 11,  6,
    11,  0,  6,
     0,  1,  6,
     6,  1, 10,
     9,  0, 11,
     9, 11,  2,
     9,  2,  5,
     7,  2, 11,
  })
  return [2]uint32{positionAccessor, indicesAccessor}
}


func rectangle(doc *gltf.Document, h float32, w float32) [2]uint32 {
  var h2 = h / 2
  var w2 = w / 2
  positionAccessor := modeler.WritePosition(doc, [][3]float32{
    { h2, 0,  w2},
    { h2, 0, -w2},
    {-h2, 0,  w2},
    {-h2, 0, -w2},
  })
  indicesAccessor := modeler.WriteIndices(doc, []uint8{
    0, 1, 3,  3, 2, 0,
    0, 2, 3,  3, 1, 0,
  })
  return [2]uint32{positionAccessor, indicesAccessor}
}


func square(doc *gltf.Document, w float32) [2]uint32 {
  return rectangle(doc, w, w)
}


func arrow(doc *gltf.Document, l float32, d float32, f float32, o float32) [2]uint32 {
  var s = d / (1 + 2 * float32(math.Sqrt(2)))
  var u = s / 2
  var v = u + s * float32(math.Sqrt(2))
  var h = l / 2
  var p1 = [3]float32{         -h,  u,  v}
  var p2 = [3]float32{         -h,  v,  u}
  var p3 = [3]float32{         -h,  v, -u}
  var p4 = [3]float32{         -h,  u, -v}
  var p5 = [3]float32{         -h, -u, -v}
  var p6 = [3]float32{         -h, -v, -u}
  var p7 = [3]float32{         -h, -v,  u}
  var p8 = [3]float32{         -h, -u,  v}
  var q1 = [3]float32{(1 - f) * h,  u,  v}
  var q2 = [3]float32{(1 - f) * h,  v,  u}
  var q3 = [3]float32{(1 - f) * h,  v, -u}
  var q4 = [3]float32{(1 - f) * h,  u, -v}
  var q5 = [3]float32{(1 - f) * h, -u, -v}
  var q6 = [3]float32{(1 - f) * h, -v, -u}
  var q7 = [3]float32{(1 - f) * h, -v,  u}
  var q8 = [3]float32{(1 - f) * h, -u,  v}
  var q0 = [3]float32{      l / 2,  0,  0}
  out := func(v [3]float32) [3]float32 {
    return [3]float32{v[0], o * v[1], o * v[2]}
  }
  mid := func(u [3]float32, v [3]float32) [3]float32 {
    return [3]float32{(u[0] + v[0]) / 2, o * (u[1] + v[1]) / 2, o * (u[2] + v[2]) / 2}
  }
  positionAccessor := modeler.WritePosition(doc, [][3]float32{
    p1        , p2        , p3        , p4        , p5        , p6        , p7        , p8        ,
    q1        , q2        , q3        , q4        , q5        , q6        , q7        , q8        ,
    out(q1)   , out(q2)   , out(q3)   , out(q4)   , out(q5)   , out(q6)   , out(q7)   , out(q8)   ,
    mid(q2,q1), mid(q3,q2), mid(q4,q3), mid(q5,q4), mid(q6,q5), mid(q7,q6), mid(q8,q7), mid(q1,q8),
    q0        ,
  })
  indicesAccessor := modeler.WriteIndices(doc, []uint8{
     0,  8,  9,   9,  1,  0,
     1,  9, 10,  10,  2,  1,
     2, 10, 11,  11,  3,  2,
     3, 11, 12,  12,  4,  3,
     4, 12, 13,  13,  5,  4,
     5, 13, 14,  14,  6,  5,
     6, 14, 15,  15,  7,  6,
     7, 15,  8,   8,  0,  7,
     0,  1,  6,   6,  7,  0,
     1,  2,  5,   5,  6,  1,
     2,  3,  4,   4,  5,  2,
     9,  8, 16,  16, 17,  9,
    10,  9, 17,  17, 18, 10,
    11, 10, 18,  18, 19, 11,
    12, 11, 19,  19, 20, 12,
    13, 12, 20,  20, 21, 13,
    14, 13, 21,  21, 22, 14,
    15, 14, 22,  22, 23, 15,
     8, 15, 23,  23, 16,  8,
    32, 17, 24,  24, 16, 32,
    32, 18, 25,  25, 17, 32,
    32, 19, 26,  26, 18, 32,
    32, 20, 27,  27, 19, 32,
    32, 21, 28,  28, 20, 32,
    32, 22, 29,  29, 21, 32,
    32, 23, 30,  30, 22, 32,
    32, 16, 31,  31, 23, 32,
  })
  return [2]uint32{positionAccessor, indicesAccessor}
}
