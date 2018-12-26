{-# LANGUAGE DeriveAnyClass        #-}
{-# LANGUAGE DeriveGeneric         #-}
{-# LANGUAGE FlexibleInstances     #-}

{-# OPTIONS_GHC -fno-warn-orphans #-}


module InfoVis.Parallel.NewTypes (
  Frame
, Identifier
, Position
, Displacement
, Rotation
, PositionRotation
, Color
, Buttons
, Geometry(..)
, Shape(..)
, Glyph(..)
) where


import Data.Aeson.Types (FromJSON, ToJSON)
import Data.Int (Int32, Int64)
import Data.Word (Word32)
import GHC.Generics (Generic)
import Linear.Affine(Point)
import Linear.Quaternion (Quaternion)
import Linear.V3 (V3)


type Frame = Int32


type Identifier = Int64


type Position = Point V3 Double

instance FromJSON Position

instance ToJSON Position


type Displacement = V3 Double

instance FromJSON Displacement

instance ToJSON Displacement


type Rotation = Quaternion Double

instance FromJSON Rotation

instance ToJSON Rotation


type PositionRotation = (Position, Rotation)


type Color = Word32


type Buttons = Word32


data Geometry =
  Geometry
  {
    shape :: Shape
  , size  :: Double
  , color :: Color
  , text  :: String
  }
    deriving (Eq, FromJSON, Generic, Ord, Read, Show, ToJSON)


data Glyph = Cube | Sphere
  deriving (Eq, FromJSON, Generic, Ord, Read, Show, ToJSON)


data Shape =
    Points Glyph [[Position]]
  | Polylines [[Position]]
  | Rectangles [(Position, Displacement, Displacement)]
  | Label (Position, Displacement, Displacement)
  | Axis (Position, Displacement)
    deriving (Eq, FromJSON, Generic, Ord, Read, Show, ToJSON)
