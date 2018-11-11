{-# LANGUAGE FlexibleInstances          #-}
{-# LANGUAGE TypeSynonymInstances       #-}

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
) where


import Data.Aeson.Types (FromJSON, ToJSON)
import Data.Int (Int32, Int64)
import Data.Word (Word32)
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
