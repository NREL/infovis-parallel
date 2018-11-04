module InfoVis.Parallel.NewTypes (
  Frame
, Identifier
, Position
, Displacement
, Rotation
, PositionRotation
, Color
) where


import Data.Int (Int32, Int64)
import Data.Word (Word32)
import Linear.Affine(Point)
import Linear.Quaternion (Quaternion)
import Linear.V3 (V3)


type Frame = Int32


type Identifier = Int64


type Position = Point V3 Double


type Displacement = V3 Double


type Rotation = Quaternion Double


type PositionRotation = (Position, Rotation)


type Color = Word32
