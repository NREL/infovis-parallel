{-# LANGUAGE ExplicitForAll      #-}
{-# LANGUAGE FlexibleContexts    #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}


module Graphics.OpenGL.Util.Projection (
  OffAxisProjection(..)
, projection
, fetchProjection
, setProjection
) where


import Data.List.Split (chunksOf)
import Graphics.Rendering.OpenGL.GL (($=!), get)
import Graphics.Rendering.OpenGL.GL.CoordTrans (GLmatrix, MatrixComponent, MatrixOrder(RowMajor), frustum, getMatrixComponents, matrix, multMatrix, newMatrix, translate)
import Graphics.OpenGL.Util.Types (Screen(..), upperRight)
import Linear.Affine (Point, (.-.))
import Linear.Epsilon (Epsilon)
import Linear.Metric (dot, normalize)
import Linear.Util.Graphics (toVector3)
import Linear.V3 (V3(..), cross)
import Linear.Vector ((*^), zero)


{-# ANN module "HLint: ignore Reduce duplication" #-}


-- | The equations to use for off-axis projection.
data OffAxisProjection =
    KooimaOffAxis -- ^ Based on Kooima 2009, \<<http://csc.lsu.edu/~kooima/pdfs/gen-perspective.pdf>\>, which assumes a rectangular screen.
  | VTKOffAxis    -- ^ Based on VTK 6.3.0, \<<https://gitlab.kitware.com/vtk/vtk/blob/v6.3.0/Rendering/Core/vtkCamera.cxx#L414>\>, which does not assume a rectangular screen.
    deriving (Eq, Read, Show)


-- | Make an off-axis projection for a screen.
projection :: forall a . (Epsilon a, MatrixComponent a, RealFloat a, Show a)
           => OffAxisProjection -- ^ The off-axis equations to use.
           -> Screen a          -- ^ The screen geometry.
           -> Point V3 a        -- ^ The eye position.
           -> a                 -- ^ The distance to the near culling plane.
           -> a                 -- ^ The distance to the far culling plane.
           -> IO ()             -- ^ An action for performing the off-axis projection.

-- Based on Kooima 2009, \<<http://csc.lsu.edu/~kooima/pdfs/gen-perspective.pdf>\>, which assumes a rectangular screen .
projection KooimaOffAxis Screen{..} eye near far =
  do
    let
      -- Orthonomal basis for screen.
      vr = normalize $ lowerRight .-. lowerLeft
      vu = normalize $ upperLeft  .-. lowerLeft
      vn = normalize $ vr `cross` vu
      -- Screen corners relative to eye.
      va = lowerLeft  .-. eye
      vb = lowerRight .-. eye
      vc = upperLeft  .-. eye
      -- Distance from eye to screen.
      throw = - va `dot` vn
      -- Extent on near clipping plane.
      scaling = near / throw
      left   = realToFrac $ (vr `dot` va) * scaling
      right  = realToFrac $ (vr `dot` vb) * scaling
      bottom = realToFrac $ (vu `dot` va) * scaling
      top    = realToFrac $ (vu `dot` vc) * scaling
      -- Matrix transforming world to screen.
      m = [[x, y, z, 0] | V3 x y z <- [vr, vu, vn]] ++ [[0, 0, 0, 1]]
    -- Perpendicator projection.
    frustum left right bottom top (realToFrac near) (realToFrac far)
    -- Rotate to non-perpendicular.
    multMatrix =<< (newMatrix RowMajor $ concat m :: IO (GLmatrix a))
    -- Move apex of frustum.
    translate . toVector3 $ zero .-. eye

    print ("LR+LL+UL+EY+NE+FA", lowerRight, lowerLeft, upperLeft, eye, near, far)
    print ("VR+VU+VN", vr, vu, vn)
    print ("VA+VB+VC", va, vb, vc)
    print ("TH", throw)
    print ("SC+LE+RI+BO+RO", scaling, left, right, bottom, top)
    print ("M", m)
    (fetchProjection :: IO [[Double]]) >>= print

-- Rewrite of VTK 6.3.0, \<<https://gitlab.kitware.com/vtk/vtk/blob/v6.3.0/Rendering/Core/vtkCamera.cxx#L414>\>, which does not assume a rectangular screen, in cleaner notation and using vector algebra.
projection VTKOffAxis s@Screen{..} eye near far =
  do
    let
      -- Orthonomal basis for screen.
      vr = normalize $ lowerRight   .-. lowerLeft
      vu = normalize $ upperRight s .-. lowerRight
      vn = normalize $ vr `cross` vu
      -- Basis for inverse.
      idet = 1 / (vr `dot` (vu `cross` vn))
      ur = idet *^ vu `cross` vn
      uu = idet *^ vn `cross` vr
      un = idet *^ vr `cross` vu
      -- Screen corners relative to eye.
      va = lowerLeft    .-. eye
      vd = upperRight s .-. eye
      -- Distance from eye to screen.
      throw = - va `dot` un
      -- Extent on near clipping plane.
      scaling = near / throw
      left   = realToFrac $ (ur `dot` va) * scaling
      right  = realToFrac $ (ur `dot` vd) * scaling
      bottom = realToFrac $ (uu `dot` va) * scaling
      top    = realToFrac $ (uu `dot` vd) * scaling
      -- Matrix transforming world to screen.
      m = [[x, y, z, 0] | V3 x y z <- [ur, uu, un]] ++ [[0, 0, 0, 1]]
    -- Perpendicator projection.
    frustum left right bottom top (realToFrac near) (realToFrac far)
    -- Rotate to non-perpendicular.
    multMatrix =<< (newMatrix RowMajor $ concat m :: IO (GLmatrix a))
    -- Move apex of frustum.
    translate . toVector3 $ zero .-. eye

-- | Retrieve the current projection matrix.
fetchProjection :: forall a . (MatrixComponent a, RealFloat a)
                => IO [[a]] -- ^ An action to retrieve the projection matrix, in row-major order.
fetchProjection =
  do
    m <- get $ matrix Nothing :: IO (GLmatrix a)
    chunksOf 4 <$> getMatrixComponents RowMajor m


setProjection :: forall a . (MatrixComponent a, RealFloat a)
              => [[a]]
              -> IO ()
setProjection m =
  do
    matrx <- newMatrix RowMajor $ concat m
    matrix Nothing $=! (matrx :: GLmatrix a)
