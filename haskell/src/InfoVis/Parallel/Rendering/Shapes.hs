module InfoVis.Parallel.Rendering.Shapes (
  Mesh
, box
, cube
, tube
, icosahedron
, rectangle
, square
, arrow
, cone
) where


import Graphics.Rendering.OpenGL.GL.PrimitiveMode (PrimitiveMode(..))
import Graphics.Rendering.OpenGL.GL.Tensor (Vertex3(..))


type Mesh a = (PrimitiveMode, [Vertex3 a])


box :: Floating a
    => a
    -> a
    -> a
    -> Mesh a
box x y z =
  let
    x' = x / 2
    y' = y / 2
    z' = z / 2
    p1 = Vertex3   x'    y'    z'
    p2 = Vertex3   x'    y'  (-z')
    p3 = Vertex3   x'  (-y')   z'
    p4 = Vertex3   x'  (-y') (-z')
    p5 = Vertex3 (-x')   y'    z'
    p6 = Vertex3 (-x')   y'  (-z')
    p7 = Vertex3 (-x') (-y')   z'
    p8 = Vertex3 (-x') (-y') (-z')
  in    
    (
      Quads
    , [
        p1, p3, p4, p2
      , p1, p2, p6, p5
      , p1, p5, p7, p3
      , p8, p4, p3, p7
      , p8, p6, p2, p4
      , p8, p7, p5, p6
      ]
    )


cube :: Floating a
     => a
     -> Mesh a
cube d = box d d d


tube :: Floating a
     => a
     -> a
     -> Mesh a
tube l d =
  let
    s = d / (1 + 2 * sqrt 2)
    u = s / 2
    v = u + s * sqrt 2
    h = l / 2
    p1 = Vertex3 (-h)   u    v 
    p2 = Vertex3 (-h)   v    u 
    p3 = Vertex3 (-h)   v  (-u)
    p4 = Vertex3 (-h)   u  (-v)
    p5 = Vertex3 (-h) (-u) (-v)
    p6 = Vertex3 (-h) (-v) (-u)
    p7 = Vertex3 (-h) (-v)   u 
    p8 = Vertex3 (-h) (-u)   v 
    q1 = Vertex3   h    u    v 
    q2 = Vertex3   h    v    u 
    q3 = Vertex3   h    v  (-u)
    q4 = Vertex3   h    u  (-v)
    q5 = Vertex3   h  (-u) (-v)
    q6 = Vertex3   h  (-v) (-u)
    q7 = Vertex3   h  (-v)   u 
    q8 = Vertex3   h  (-u)   v 
  in
    (
      Quads
    , [
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
    )


icosahedron :: Floating a
            => a
            -> Mesh a
icosahedron d =
  let
    phi = (1 + sqrt 5) / 2
    x = d / 2 / sqrt (1 + phi * phi)
    z = phi * x
    n = 0
    p00 = Vertex3 (-x)   n    z
    p01 = Vertex3   x    n    z
    p02 = Vertex3 (-x)   n  (-z)
    p03 = Vertex3   x    n  (-z)
    p04 = Vertex3   n    z    x
    p05 = Vertex3   n    z  (-x)
    p06 = Vertex3   n  (-z)   x
    p07 = Vertex3   n  (-z) (-x)
    p08 = Vertex3   z    x    n
    p09 = Vertex3 (-z)   x    n
    p10 = Vertex3   z  (-x)   n
    p11 = Vertex3 (-z) (-x)   n
  in
    (
      Triangles
    , [ 
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
    )


rectangle :: Floating a
          => a
          -> a
          -> Mesh a
rectangle h w =
  let
    h2 = h / 2
    w2 = w / 2
    p1 = Vertex3   h2  0   w2
    p2 = Vertex3   h2  0 (-w2)
    p3 = Vertex3 (-h2) 0   w2
    p4 = Vertex3 (-h2) 0 (-w2)
  in
    (
      Quads
    , [
        p1, p2, p4, p3
      , p1, p3, p4, p2
      ]
    )


square :: Floating a
       => a
       -> Mesh a
square w = rectangle w w


arrow :: (Floating a, Ord a)
      => a
      -> a
      -> a
      -> a
      -> Mesh a
arrow l d f o =
  let
    t =
      [
        Vertex3 (if x > 0 then (1 - f) * x else x) y z
      |
        Vertex3 x y z <- snd $ tube l d
      ]
    q0 = Vertex3 (l / 2) 0 0
    q1 = t !!  1
    q2 = t !!  2
    q3 = t !!  6
    q4 = t !! 10
    q5 = t !! 14
    q6 = t !! 18
    q7 = t !! 22
    q8 = t !! 26
    out (Vertex3 x y z) = Vertex3 x (o * y) (o * z)
    mid (Vertex3 x y z) (Vertex3 x' y' z') = Vertex3 ((x + x') / 2) (o * (y + y') / 2) (o * (z + z') / 2)
  in
    (
      Quads
    , t
      ++
      [
        q2, q1, out q1   , out q2
      , q3, q2, out q2   , out q3
      , q4, q3, out q3   , out q4
      , q5, q4, out q4   , out q5
      , q6, q5, out q5   , out q6
      , q7, q6, out q6   , out q7
      , q8, q7, out q8   , out q8
      , q1, q8, out q8   , out q1
      , q0, out q2, mid q2 q1, out q1
      , q0, out q3, mid q3 q2, out q2
      , q0, out q4, mid q4 q3, out q3
      , q0, out q5, mid q5 q4, out q4
      , q0, out q6, mid q6 q5, out q5
      , q0, out q7, mid q7 q6, out q6
      , q0, out q8, mid q8 q7, out q7
      , q0, out q1, mid q1 q8, out q8
      ]
    )


cone :: Floating a
     => a
     -> a
     -> Mesh a
cone l d =
  let
    r = d / 2
    n = 32
    alpha = 2 * pi / fromIntegral n
  in
    (
      Triangles
    , concat
        [
          [
            Vertex3 0 0                           0
          , Vertex3 l (r * cos (alpha *  i     )) (r * sin (alpha *  i     ))
          , Vertex3 l (r * cos (alpha * (i + 1))) (r * sin (alpha * (i + 1)))
          , Vertex3 l (r * cos (alpha * (i + 1))) (r * sin (alpha * (i + 1)))
          , Vertex3 l (r * cos (alpha *  i     )) (r * sin (alpha *  i     ))
          , Vertex3 l 0                           0
          ]
        |
          i' <- [1..n] :: [Int]
        , let i = fromIntegral i'
        ]
    )
