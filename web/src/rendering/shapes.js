
const vec3 = glMatrix.vec3


function box(x, y, z) {

  const x1 = x / 2
  const y1 = y / 2
  const z1 = z / 2
  const p1 = vec3.fromValues( x1,  y1,  z1)
  const p2 = vec3.fromValues( x1,  y1, -z1)
  const p3 = vec3.fromValues( x1, -y1,  z1)
  const p4 = vec3.fromValues( x1, -y1, -z1)
  const p5 = vec3.fromValues(-x1,  y1,  z1)
  const p6 = vec3.fromValues(-x1,  y1, -z1)
  const p7 = vec3.fromValues(-x1, -y1,  z1)
  const p8 = vec3.fromValues(-x1, -y1, -z1)

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

  const s = d / (1 + 2 * Math.sqrt(2))
  const u = s / 2
  const v = u + s * Math.sqrt(2)
  const h = l / 2
  const p1 = vec3.fromValues(-h,  u,  v)
  const p2 = vec3.fromValues(-h,  v,  u)
  const p3 = vec3.fromValues(-h,  v, -u)
  const p4 = vec3.fromValues(-h,  u, -v)
  const p5 = vec3.fromValues(-h, -u, -v)
  const p6 = vec3.fromValues(-h, -v, -u)
  const p7 = vec3.fromValues(-h, -v,  u)
  const p8 = vec3.fromValues(-h, -u,  v)
  const q1 = vec3.fromValues( h,  u,  v)
  const q2 = vec3.fromValues( h,  v,  u)
  const q3 = vec3.fromValues( h,  v, -u)
  const q4 = vec3.fromValues( h,  u, -v)
  const q5 = vec3.fromValues( h, -u, -v)
  const q6 = vec3.fromValues( h, -v, -u)
  const q7 = vec3.fromValues( h, -v,  u)
  const q8 = vec3.fromValues( h, -u,  v)

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

  const phi = (1 + Math.sqrt(5)) / 2
  const x = d / 2 / Math.sqrt(1 + phi * phi)
  const z = phi * x
  const n = 0
  const p00 = vec3.fromValues(-x,  n,  z)
  const p01 = vec3.fromValues( x,  n,  z)
  const p02 = vec3.fromValues(-x,  n, -z)
  const p03 = vec3.fromValues( x,  n, -z)
  const p04 = vec3.fromValues( n,  z,  x)
  const p05 = vec3.fromValues( n,  z, -x)
  const p06 = vec3.fromValues( n, -z,  x)
  const p07 = vec3.fromValues( n, -z, -x)
  const p08 = vec3.fromValues( z,  x,  n)
  const p09 = vec3.fromValues(-z,  x,  n)
  const p10 = vec3.fromValues( z, -x,  n)
  const p11 = vec3.fromValues(-z, -x,  n)

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

  const h2 = h / 2
  const w2 = w / 2
  const p1 = vec3.fromValues( h2, 0,  w2)
  const p2 = vec3.fromValues( h2, 0, -w2)
  const p3 = vec3.fromValues(-h2, 0,  w2)
  const p4 = vec3.fromValues(-h2, 0, -w2)

  // Quads.
  return [
    p1, p2, p4, p3
  , p1, p3, p4, p2
  ]

}


function square(w) {
  return rectangle(w, w)
}


function arrow(l, d, f, o) {

  const t = tube(l, d).map((v) => vec3.fromValues(v[0] > 0 ? (1 - f) * v[0] : v[0], v[1], v[2]))
  const q0 = vec3.fromValues(l / 2, 0, 0)
  const q1 = t[ 1]
  const q2 = t[ 2]
  const q3 = t[ 6]
  const q4 = t[10]
  const q5 = t[14]
  const q6 = t[18]
  const q7 = t[22]
  const q8 = t[26]

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
  , q8,     q7 , out(q7)    , out(q8)
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

  const r = d / 2
  const n = 32
  const alpha = 2 * Math.PI / n

  // Triangles.
  return Array.from({length: n}, (v, k) => k + 1).map((i) =>
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
  return Array.from({length: vs.length / 4}, (v, k) => 4 * k).map((i) =>
    [
      vs[i  ], vs[i+1], vs[i+2]
    , vs[i+2], vs[i+3], vs[i  ]
    ]
  ).flat()
}


export default {
  box         : function(x, y, z   ) {return fromQuads(box      (x, y, z   ))}
, cube        : function(d         ) {return fromQuads(cube     (d         ))}
, tube        : function(l, d      ) {return fromQuads(tube     (l, d      ))}
, icosahedron : icosahedron
, rectangle   : function(h, w      ) {return fromQuads(rectangle(h, w      ))}
, square      : function(w         ) {return fromQuads(square   (w         ))}
, arrow       : function(l, d, f, o) {return fromQuads(arrow    (l, d, f, o))}
, cone        : cone
}
