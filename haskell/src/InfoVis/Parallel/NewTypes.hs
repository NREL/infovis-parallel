{-# LANGUAGE DeriveAnyClass             #-}
{-# LANGUAGE FlexibleInstances          #-}
{-# LANGUAGE StandaloneDeriving         #-}
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

deriving instance FromJSON Position

deriving instance ToJSON Position


type Displacement = V3 Double

deriving instance FromJSON Displacement

deriving instance ToJSON Displacement


type Rotation = Quaternion Double

deriving instance FromJSON Rotation

deriving instance ToJSON Rotation


type PositionRotation = (Position, Rotation)


type Color = Word32
