module Linear.Util (
  orthogonal
, rotationFromVectorPair
, projectPlane
, rotationFromVectorPairs
, rotationFromPlane
, fromEuler
, fromEulerd
, toEuler
, toEulerd
, distanceToPoint
, distanceToSegment
, distanceToRectangle
, distanceToBox
, toPoint
, toVector3
, toQuaternion
) where


import Data.Math.Util (fromDegrees, toDegrees)
import Linear.Affine (Point(..), (.-.))
import Linear.Conjugate (Conjugate, conjugate)
import Linear.Epsilon (Epsilon(nearZero))
import Linear.Matrix ((!*), inv33)
import Linear.Metric (dot, norm, normalize)
import Linear.Quaternion (Quaternion(..), axisAngle, rotate)
import Linear.V3 (V3(..), cross)
import Linear.Vector ((^+^), (^-^), (*^), basis)


-- http://stackoverflow.com/questions/1171849/finding-quaternion-representing-the-rotation-from-one-vector-to-another
rotationFromVectorPair :: (Epsilon a, Eq a, RealFloat a) => V3 a -> V3 a -> Quaternion a
rotationFromVectorPair v1 v2 =
  let v1n = normalize v1
      v2n = normalize v2
      v12 = v1n ^+^ v2n
      v12n = normalize v12
      q = Quaternion (v12n `dot` v2n) $ v12n `cross` v2n
  in
    if nearZero v12
      then Quaternion 0 $ orthogonal v1n
      else q


orthogonal :: (Epsilon a, Eq a, Floating a) => V3 a -> V3 a
orthogonal =
  normalize
    . head
    . filter (not . nearZero)
    . (`map` basis)
    . cross


projectPlane :: (Epsilon a, Floating a) => V3 a -> V3 a -> V3 a
projectPlane v u =
  let
    un = normalize u
  in
    v ^-^ (v `dot` un) *^ un


rotationFromVectorPairs :: (Conjugate a, Epsilon a, RealFloat a) => V3 a -> V3 a -> V3 a -> V3 a -> Quaternion a
rotationFromVectorPairs u0 v0 u2 v2 =
  let
    q2 = rotationFromVectorPair u0 u2
    v1 = conjugate q2 `rotate` v2
    v0p = normalize $ v0 `projectPlane` u0
    v1p = normalize $ v1 `projectPlane` u0
    q1 =
      if nearZero $ v0p ^+^ v1p
        then Quaternion 0 $ normalize u0
        else rotationFromVectorPair v0p v1p
  in
    normalize $ q2 * q1


rotationFromPlane :: (Conjugate a, Epsilon a, RealFloat a) => V3 a -> V3 a -> Point V3 a -> Point V3 a -> Point V3 a -> Quaternion a
rotationFromPlane xAxis yAxis origin xPoint yPoint =
  rotationFromVectorPairs
    xAxis
    yAxis
    (xPoint .-. origin)
    (yPoint .-. origin)


{-
http://robokitchen.tumblr.com/post/67060392720/finding-a-rotation-quaternion-from-two-pairs-of
http://stackoverflow.com/questions/4670070/deriving-axis-angle-rotation-from-two-pairs-of-three-points-or-two-pairs-of-tw
Before rotation: u0, v0. After rotation: u2, v2.
Quaternion q2 = Quaternion::fromTwoVectors(u0, u2);
Vector v1 = v2.rotate(q2.conjugate());
Vector v0_proj = v0.projectPlane(u0);
Vector v1_proj = v1.projectPlane(u0);
Quaternion q1 = Quaternion::fromTwoVectors(v0_proj, v1_proj);
return (q2 * q1).normalized();
-}


fromEuler :: (Epsilon a, Num a, RealFloat a) => V3 a -> Quaternion a
fromEuler (V3 phi theta psi) =
  let
    [ex, ey, ez] = basis
  in
    ez `axisAngle` psi * ey `axisAngle` theta * ex `axisAngle` phi


fromEulerd :: (Epsilon a, Num a, RealFloat a) => V3 a -> Quaternion a
fromEulerd = fromEuler . fmap fromDegrees


toEuler :: (Num a, RealFloat a) => Quaternion a -> V3 a
toEuler (Quaternion w (V3 x y z)) =
  let
    phi = atan2 (2 * (w * x  + y * z)) (1 - 2 * (x * x + y * y))
    theta = asin (2 * (w * y - z * x))
    psi = atan2 (2 * (w * z + x * y)) (1 - 2 * (y * y + z * z))
  in
    V3 phi theta psi


toEulerd :: (Num a, RealFloat a) => Quaternion a -> V3 a
toEulerd = fmap toDegrees . toEuler


distanceToPoint :: (Epsilon a, Floating a) => Point V3 a -> Point V3 a -> a
distanceToPoint po ps = norm $ ps .-. po


distanceToSegment  :: (Epsilon a, Floating a, Ord a) => Point V3 a -> Point V3 a -> Point V3 a -> a
distanceToSegment po pu ps =
  let
    (abg, uvw) = boxCoordinates po pu Nothing Nothing ps
  in
    norm $ distanceOnSegment <$> uvw <*> abg


distanceToRectangle :: (Epsilon a, Floating a, Ord a) => Point V3 a -> Point V3 a -> Point V3 a -> Point V3 a -> a
distanceToRectangle po pu pv ps =
  let
    (abg, uvw) = boxCoordinates po pu (Just pv) Nothing ps
  in
    norm $ distanceOnSegment <$> uvw <*> abg


distanceToBox :: (Epsilon a, Floating a, Ord a) => Point V3 a -> Point V3 a -> Point V3 a -> Point V3 a -> Point V3 a -> a
distanceToBox po pu pv pw ps =
  let
    (abg, uvw) = boxCoordinates po pu (Just pv) (Just pw) ps
  in
    norm $ distanceOnSegment <$> uvw <*> abg


distanceOnSegment :: (Num a, Ord a) => a -> a -> a
distanceOnSegment un alpha
  | alpha <= 0  = - alpha
  | alpha >= un = alpha - un
  | otherwise   = 0


boxCoordinates :: (Epsilon a, Floating a, Ord a)
               => Point V3 a
               -> Point V3 a
               -> Maybe (Point V3 a)
               -> Maybe (Point V3 a)
               -> Point V3 a
               -> (V3 a, V3 a)
boxCoordinates po pu pv pw ps =
  let
    s = ps .-. po
    u = pu .-. po
    e = head $ filter (not . nearZero . dot u) basis
    v = maybe (u `cross` e) (.-. po) pv
    w = maybe (u `cross` v) (.-. po) pw
    uh = normalize u
    vh = normalize v
    wh = normalize w
    uv = uh `dot` vh
    wu = wh `dot` uh
    vw = vh `dot` wh
    mi = inv33 $ V3 (V3 1 uv wu) (V3 uv 1 vw) (V3 wu vw 1)
  in
    (
      mi !* (dot s <$> V3 uh vh wh)
    , V3 (norm u) (maybe 0 (const $ norm v) pv) (maybe 0 (const $ norm w) pw)
    )


toPoint :: (a, a, a)
        -> Point V3 a
toPoint = P . toVector3


toVector3 :: (a, a, a)
          -> V3 a
toVector3 (x, y, z) = V3 x y z


toQuaternion :: (a, a, a, a)
             -> Quaternion a
toQuaternion (w, x, y, z) = Quaternion w $ V3 x y z
