{-# LANGUAGE DeriveAnyClass    #-}
{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE FlexibleInstances #-}


module InfoVis.Parallel.Presenter.Extent (
  Scalable(..)
, Extent(..)
) where


import Data.Aeson.Types (FromJSON(..), ToJSON(..))
import Data.Binary (Binary)
import GHC.Generics (Generic)
import InfoVis.Parallel.Types (Geometry(..), Position, Shape(..))
import Linear.Affine ((.-.), (.+^))
import Linear.Matrix ((!*), transpose)
import Linear.V3 (V3(..))
import Linear.Vector (zero)


class Scalable a where
  scale :: Extent -> a -> a


data Extent =
    Extent1D
    {
      origin  :: Position
    , cornerX :: Position
    }
  | Extent2D
    {
      origin  :: Position
    , cornerX :: Position
    , cornerY :: Position
    }
  | Extent3D
    {
      origin  :: Position
    , cornerX :: Position
    , cornerY :: Position
    , cornerZ :: Position
    }
    deriving (Binary, Eq, FromJSON, Generic, Ord, Read, Show, ToJSON)


instance Scalable Position where
  scale Extent1D{..} = scaling origin cornerX zero    zero
  scale Extent2D{..} = scaling origin cornerX cornerY zero
  scale Extent3D{..} = scaling origin cornerX cornerY cornerZ


instance Scalable Geometry where
  scale extent geometry@Geometry{..} = geometry {shape = scale extent shape}


instance Scalable Shape where
  scale extent (Points glyph positions) = Points glyph $ fmap (scale extent) <$> positions
  scale extent (Polylines    positions) = Polylines    $ fmap (scale extent) <$> positions
  scale extent (Rectangles   positions) = Rectangles   $ scaleTriplet extent <$> positions
  scale extent (Label        positions) = Label        $ scaleTriplet extent     positions
  scale extent (Axis         positions) = Axis         $ scaleDoublet extent     positions


scaleDoublet :: Extent
             -> (Position, Position)
             -> (Position, Position)
scaleDoublet extent (p1, p2) = (scale extent p1, scale extent p2)


scaleTriplet :: Extent
             -> (Position, Position, Position)
             -> (Position, Position, Position)
scaleTriplet extent (p1, p2, p3) = (scale extent p1, scale extent p2, scale extent p3)


scaling :: Position
        -> Position
        -> Position
        -> Position
        -> Position
        -> Position
scaling o u v w p = o .+^ transpose (V3 (u .-. o) (v .-. o) (w .-. o)) !* (p .-. o)
