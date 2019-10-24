
require("../gl-matrix")


const vec3 = glMatrix.vec3


function box(x, y, z) {

  x1 = x / 2
  y1 = y / 2
  z1 = z / 2
  p1 = vec3.fromValues( x1,  y1,  z1)
  p2 = vec3.fromValues( x1,  y1, -z1)
  p3 = vec3.fromValues( x1, -y1,  z1)
  p4 = vec3.fromValues( x1, -y1, -z1)
  p5 = vec3.fromValues(-x1,  y1,  z1)
  p6 = vec3.fromValues(-x1,  y1, -z1)
  p7 = vec3.fromValues(-x1, -y1,  z1)
  p8 = vec3.fromValues(-x1, -y1, -z1)

  // Quads.
  return [
    p1, p3, p4, p2
  , p1, p2, p6, p5
  , p1, p5, p7, p3
  , p8, p4, p3, p7
  , p8, p6, p2, p4
  , p8, p7, p5, p6
  ]

}


function cube(d) {
  return box(d, d, d)
}


function tube(l, d) {

  s = d / (1 + 2 * Math.sqrt(2))
  u = s / 2
  v = u + s * Math.sqrt(2)
  h = l / 2
  p1 = vec3.fromValues(-h,  u,  v)
  p2 = vec3.fromValues(-h,  v,  u)
  p3 = vec3.fromValues(-h,  v, -u)
  p4 = vec3.fromValues(-h,  u, -v)
  p5 = vec3.fromValues(-h, -u, -v)
  p6 = vec3.fromValues(-h, -v, -u)
  p7 = vec3.fromValues(-h, -v,  u)
  p8 = vec3.fromValues(-h, -u,  v)
  q1 = vec3.fromValues( h,  u,  v)
  q2 = vec3.fromValues( h,  v,  u)
  q3 = vec3.fromValues( h,  v, -u)
  q4 = vec3.fromValues( h,  u, -v)
  q5 = vec3.fromValues( h, -u, -v)
  q6 = vec3.fromValues( h, -v, -u)
  q7 = vec3.fromValues( h, -v,  u)
  q8 = vec3.fromValues( h, -u,  v)

  // Quads.
  return [
    p1, q1, q2, p2
  , p2, q2, q3, p3
  , p3, q3, q4, p4
  , p4, q4, q5, p5
  , p5, q5, q6, p6
  , p6, q6, q7, p7
  , p7, q7, q8, p8
  , p8, q8, q1, p1
  , p1, p2, p7, p8
  , p2, p3, p6, p7
  , p3, p4, p5, p6
  , q8, q7, q2, q1
  , q7, q6, q3, q2
  , q6, q5, q4, q3
  ]

}


function icosahedron(d) {

  phi = (1 + Math.sqrt(5)) / 2
  x = d / 2 / Math.sqrt(1 + phi * phi)
  z = phi * x
  n = 0
  p00 = vec3.fromValues(-x,  n,  z)
  p01 = vec3.fromValues( x,  n,  z)
  p02 = vec3.fromValues(-x,  n, -z)
  p03 = vec3.fromValues( x,  n, -z)
  p04 = vec3.fromValues( n,  z,  x)
  p05 = vec3.fromValues( n,  z, -x)
  p06 = vec3.fromValues( n, -z,  x)
  p07 = vec3.fromValues( n, -z, -x)
  p08 = vec3.fromValues( z,  x,  n)
  p09 = vec3.fromValues(-z,  x,  n)
  p10 = vec3.fromValues( z, -x,  n)
  p11 = vec3.fromValues(-z, -x,  n)

  // Triangles.
  return [
    p00, p04, p01
  , p00, p09, p04
  , p09, p05, p04
  , p04, p05, p08
  , p04, p08, p01
  , p08, p10, p01
  , p08, p03, p10
  , p05, p03, p08
  , p05, p02, p03
  , p02, p07, p03
  , p07, p10, p03
  , p07, p06, p10
  , p07, p11, p06
  , p11, p00, p06
  , p00, p01, p06
  , p06, p01, p10
  , p09, p00, p11
  , p09, p11, p02
  , p09, p02, p05
  , p07, p02, p11
  ]

}


function rectangle(h, w) {

  h2 = h / 2
  w2 = w / 2
  p1 = vec3.fromValues( h2, 0,  w2)
  p2 = vec3.fromValues( h2, 0, -w2)
  p3 = vec3.fromValues(-h2, 0,  w2)
  p4 = vec3.fromValues(-h2, 0, -w2)

  // Quads.
  return [
    p1, p2, p4, p3
  , p1, p3, p4, p2
  ]

}


function square(w) {
  rectangle(w, w)
}


function arrow(l, d, f, o) {

  t = tube(l, d).map(v => vec3.fromValues(v[0] > 0 ? (1 - f) * v[0] : v[0], v[1], v[2]))
  q0 = vec3.fromValues(l / 2, 0, 0)
  q1 = t[ 1]
  q2 = t[ 2]
  q3 = t[ 6]
  q4 = t[10]
  q5 = t[14]
  q6 = t[18]
  q7 = t[22]
  q8 = t[26]
  function out(v) {
    return vec3.fromValues(v[0], o * v[1], o * v[2])
  }
  function mid(u, v) {
    return vec3.fromValues((u[0] + v[0]) / 2, o * (u[1] + v[1]) / 2, o * (u[2] + v[2]) / 2)
  }

  // Quads.
  return t.concat([
    q2,     q1 , out(q1)    , out(q2)
  , q3,     q2 , out(q2)    , out(q3)
  , q4,     q3 , out(q3)    , out(q4)
  , q5,     q4 , out(q4)    , out(q5)
  , q6,     q5 , out(q5)    , out(q6)
  , q7,     q6 , out(q6)    , out(q7)
  , q8,     q7 , out(q8)    , out(q8)
  , q1,     q8 , out(q8)    , out(q1)
  , q0, out(q2), mid(q2, q1), out(q1)
  , q0, out(q3), mid(q3, q2), out(q2)
  , q0, out(q4), mid(q4, q3), out(q3)
  , q0, out(q5), mid(q5, q4), out(q4)
  , q0, out(q6), mid(q6, q5), out(q5)
  , q0, out(q7), mid(q7, q6), out(q6)
  , q0, out(q8), mid(q8, q7), out(q7)
  , q0, out(q1), mid(q1, q8), out(q8)
  ])

}


function cone(l, d) {

  r = d / 2
  n = 32
  alpha = 2 * Math.PI / n

  // Triangles.
  return Array.from({length: n}, (v, k) => k + 1).map(i =>
    [
      vec3.fromValues(0, 0                            , 0                            )
    , vec3.fromValues(l, r * Math.cos(alpha *  i     ), r * Math.sin(alpha *  i     ))
    , vec3.fromValues(l, r * Math.cos(alpha * (i + 1)), r * Math.sin(alpha * (i + 1)))
    , vec3.fromValues(l, r * Math.cos(alpha * (i + 1)), r * Math.sin(alpha * (i + 1)))
    , vec3.fromValues(l, r * Math.cos(alpha *  i     ), r * Math.sin(alpha *  i     ))
    , vec3.fromValues(l, 0                            , 0                            )
    ]
  ).flat()

}


function fromQuads(vs) {
  return Array.from({length: vs.length / 4}, (v, k) => 4 * k).map(i =>
    [
      vs[i  ], vs[i+1], vs[i+2]
    , vs[i+2], vs[i+3], vs[i  ]
    ]
  ).flat()
}


module.exports = {
  box         : function(x, y, z   ) {return fromQuads(box      (x, y, z   ))}
, cube        : function(d         ) {return fromQuads(cube     (d         ))}
, tube        : function(l, d      ) {return fromQuads(tube     (l, d      ))}
, icosahedron : icosahedron
, rectangle   : function(h, w      ) {return fromQuads(rectangle(h, w      ))}
, square      : function(w         ) {return fromQuads(square   (w         ))}
, arrow       : function(l, d, f, o) {return fromQuads(arrow    (l, d, f, o))}
, cone        : cone
}
