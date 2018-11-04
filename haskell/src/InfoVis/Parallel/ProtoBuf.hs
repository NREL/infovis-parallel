{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE DeriveAnyClass        #-}
{-# LANGUAGE DeriveGeneric         #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE RecordWildCards       #-}
{-# LANGUAGE StandaloneDeriving    #-}


module InfoVis.Parallel.ProtoBuf (
  Request
, reset
, upsert
, delete
, viewSet
, toolSet
, Response
, message
, hover
, unhover
, select
, deselect
, viewGet
, toolGet
, Geometry(..)
, Shape(..)
) where


import Control.Lens.Getter ((^.))
import Control.Lens.Lens (Lens', lens)
import Control.Lens.Tuple (_1, _2, _3, _4, _5)
import Control.Monad (guard)
import Data.Aeson.Types (FromJSON, ToJSON)
import Data.Bits (Bits, (.|.), (.&.), shift)
import Data.Default (Default(..))
import Data.Int (Int32, Int64)
import Data.List.Split (splitPlaces)
import Data.Maybe (fromMaybe)
import Data.Word (Word32)
import Data.ProtocolBuffers (Decode, Encode, Message, Optional, Repeated, Value, getField, putField)
import GHC.Generics (Generic)
import InfoVis.Parallel.NewTypes (Color, Displacement, Frame, Identifier, Position, PositionRotation)
import Linear.Affine (Point(..))
import Linear.Quaternion (Quaternion(..))
import Linear.V3 (V3(..))


data Request =
  Request
  {
    reset'   :: Optional 1 (Value   Bool    )
  , upsert'  :: Repeated 2 (Message GeometryPB)
  , delete'  :: Repeated 3 (Value   Int64   )
  , viewloc' :: Optional 4 (Message LocationPB)
  , toolloc' :: Optional 5 (Message LocationPB)
  }
    deriving (Generic, Show)

instance Default Request where
  def =
    Request
    {
      reset'   = putField Nothing
    , upsert'  = putField []
    , delete'  = putField []
    , viewloc' = putField Nothing
    , toolloc' = putField Nothing
    }

deriving instance Decode Request

deriving instance Encode Request


reset :: Lens' Request Bool
reset =
  lens
    (fromMaybe False . getField . reset')
    (\s x -> s {reset' = putField $ Just x})


upsert :: Lens' Request [Geometry]
upsert =
  lens
    (fmap toGeometry . getField . upsert')
    (\s x -> s {upsert' = putField $ fromGeometry <$> x})


delete :: Lens' Request [Identifier]
delete =
  lens
    (getField . delete')
    (\s x -> s {delete' = putField x})


viewSet :: Lens' Request (Maybe PositionRotation)
viewSet =
  lens
    (fmap toPositionRotation . getField . (viewloc' :: Request -> Optional 4 (Message LocationPB)))
    (\s x -> (s :: Request) {viewloc' = putField $ fromPositionRotation <$> x})


toolSet :: Lens' Request (Maybe PositionRotation)
toolSet =
  lens
    (fmap toPositionRotation . getField . (toolloc' :: Request -> Optional 5 (Message LocationPB)))
    (\s x -> (s :: Request) {toolloc' = putField $ fromPositionRotation <$> x})


data Response =
  Response
  {
    message'  :: Optional 1 (Value   String  )
  , hover'    :: Repeated 2 (Value   Int64   )
  , unhover'  :: Repeated 3 (Value   Int64   )
  , select'   :: Repeated 4 (Value   Int64   )
  , deselect' :: Repeated 5 (Value   Int64   )
  , viewloc'  :: Optional 6 (Message LocationPB)
  , toolloc'  :: Optional 7 (Message LocationPB)
  }
    deriving (Generic, Show)

instance Default Response where
  def = 
    Response
    {
      message'  = putField def
    , hover'    = putField def
    , unhover'  = putField def
    , select'   = putField def
    , deselect' = putField def
    , viewloc'  = putField def
    , toolloc'  = putField def
    }

deriving instance Decode Response

deriving instance Encode Response


message :: Lens' Response (Maybe String)
message =
  lens
    (getField . message')
    (\s x -> s {message' = putField x})


hover :: Lens' Response [Identifier]
hover =
  lens
    (getField . hover')
    (\s x -> s {hover' = putField x})


unhover :: Lens' Response [Identifier]
unhover =
  lens
    (getField . unhover')
    (\s x -> s {unhover' = putField x})


select :: Lens' Response [Identifier]
select =
  lens
    (getField . select')
    (\s x -> s {select' = putField x})


deselect :: Lens' Response [Identifier]
deselect =
  lens
    (getField . deselect')
    (\s x -> s {deselect' = putField x})


viewGet :: Lens' Response (Maybe PositionRotation)
viewGet =
  lens
    (fmap toPositionRotation . getField . (viewloc' :: Response -> Optional 6 (Message LocationPB)))
    (\s x -> (s :: Response) {viewloc' = putField $ fromPositionRotation <$> x})


toolGet :: Lens' Response (Maybe PositionRotation)
toolGet =
  lens
    (fmap toPositionRotation . getField . (toolloc' :: Response -> Optional 7 (Message LocationPB)))
    (\s x -> (s :: Response) {toolloc' = putField $ fromPositionRotation <$> x})


data GeometryPB =
  GeometryPB
  {
    fram' :: Optional  1 (Value Int32 )
  , iden' :: Optional  2 (Value Int64 )
  , typp' :: Optional  3 (Value Int32 )
  , mask' :: Optional  4 (Value Int32 )
  , cnts' :: Repeated  5 (Value Int32 )
  , posx' :: Repeated  6 (Value Double)
  , posy' :: Repeated  7 (Value Double)
  , posz' :: Repeated  8 (Value Double)
  , size' :: Optional  9 (Value Double)
  , colr' :: Optional 10 (Value Word32)
  , text' :: Optional 11 (Value String)
  }
    deriving (Generic, Show)

deriving instance Decode GeometryPB

deriving instance Encode GeometryPB


data Geometry =
  Geometry
  {
    frame      :: Frame
  , identifier :: Identifier
  , shape      :: Maybe Shape
  , size       :: Maybe Double
  , color      :: Maybe Color
  , text       :: Maybe String
  }
    deriving (Eq, FromJSON, Generic, Ord, Read, Show, ToJSON)


shapeBit :: (Bits a, Num a) => a
shapeBit = 1 `shift` 0


sizeBit :: (Bits a, Num a) => a
sizeBit = 1 `shift` 1


colorBit :: (Bits a, Num a) => a
colorBit = 1 `shift` 2


textBit :: (Bits a, Num a) => a
textBit = 1 `shift` 3


toGeometry :: GeometryPB -> Geometry
toGeometry GeometryPB{..} =
  let
    frame      = fromMaybe 0 $ getField fram'
    identifier = fromMaybe 0 $ getField iden'
    mask       = fromMaybe 0 $ getField mask'
    shape =
      do
        guard
          $ shapeBit .&. mask /= 0
        toShape
          (
            getField typp'
          , getField cnts'
          , getField posx'
          , getField posy'
          , getField posz'
          )
    size       = guard (sizeBit  .&. mask /= 0) >> return (fromMaybe 0  $ getField size')
    color      = guard (colorBit .&. mask /= 0) >> return (fromMaybe 0  $ getField colr')
    text       = guard (textBit  .&. mask /= 0) >> return (fromMaybe "" $ getField text')
  in
    Geometry{..}


fromGeometry :: Geometry -> GeometryPB
fromGeometry Geometry{..} =
  let
    mask =
        maybe (shapeBit .|.) (const id) shape
      . maybe (sizeBit  .|.) (const id) size
      . maybe (colorBit .|.) (const id) color
      . maybe (textBit  .|.) (const id) text
      $ 0
    shape' = fromShape <$> shape
  in
    GeometryPB
    {
      fram' = putField $ Just frame
    , iden' = putField $ Just identifier
    , typp' = putField $ (^. _1) <$> shape'
    , mask' = putField $ Just mask
    , cnts' = putField $ maybe [] (^. _2) shape'
    , posx' = putField $ maybe [] (^. _3) shape'
    , posy' = putField $ maybe [] (^. _4) shape'
    , posz' = putField $ maybe [] (^. _5) shape'
    , size' = putField size
    , colr' = putField color
    , text' = putField text
    }


data Shape =
    Points [[Position]]
  | Polylines [[Position]]
  | Rectangles [(Position, Displacement, Displacement)]
  | Label (Position, Displacement, Displacement)
  | Axis (Position, Displacement)
    deriving (Eq, FromJSON, Generic, Ord, Read, Show, ToJSON)


toShape :: (Maybe Int32, [Int32], [Double], [Double], [Double]) -> Maybe Shape
toShape (ty', cs, xs, ys, zs) =
  do
    ty <- ty'
    let
      n = fromIntegral $ sum cs
      ps = zipWith3 V3 xs ys zs
      to2 [origin, horizontal] = (P origin, horizontal)
      to2 _ = undefined
      to3 [origin, horizontal, vertical] = (P origin, horizontal, vertical)
      to3 _ = undefined
    guard
      $  n == length xs
      && n == length ys
      && n == length zs
    case ty of
      1 -> return . Points    . splitPlaces cs $ P <$> ps
      2 -> return . Polylines . splitPlaces cs $ P <$> ps
      3 -> do
             guard
               $ all (== 3) cs
             return
               . Rectangles
               $ to3
               <$> splitPlaces cs ps
      4 -> do
             guard
               $ n == 3 && length cs == 1
             return
               . Label
               $ to3 ps
      5 -> do
             guard
               $ n == 2 && length cs == 1
             return
               . Axis
               $ to2 ps
      _ -> Nothing


fromShape :: Shape -> (Int32, [Int32], [Double], [Double], [Double])
fromShape (Points pointSets) =
  let
    cs = fromIntegral . length <$> pointSets
    xs = concatMap (fmap $ \(P (V3 x _ _)) -> x) pointSets
    ys = concatMap (fmap $ \(P (V3 _ y _)) -> y) pointSets
    zs = concatMap (fmap $ \(P (V3 _ _ z)) -> z) pointSets
  in
    (1, cs, xs, ys, zs)
fromShape (Polylines polylines) =
  let
    cs = fromIntegral . length <$> polylines
    xs = concatMap (fmap $ \(P (V3 x _ _)) -> x) polylines
    ys = concatMap (fmap $ \(P (V3 _ y _)) -> y) polylines
    zs = concatMap (fmap $ \(P (V3 _ _ z)) -> z) polylines
  in
    (2, cs, xs, ys, zs)
fromShape (Rectangles rectangles) =
  let
    cs = fmap (const 3) rectangles
    xs = concatMap (\(P (V3 x0 _  _ ), V3 x1 _  _ , V3 x2 _  _ ) -> [x0, x1, x2]) rectangles
    ys = concatMap (\(P (V3 _  y0 _ ), V3 _  y1 _ , V3 _  y2 _ ) -> [y0, y1, y2]) rectangles
    zs = concatMap (\(P (V3 _  _  z0), V3 _  _  z1, V3 _  _  z2) -> [z0, z1, z2]) rectangles
  in
    (3, cs, xs, ys, zs)
fromShape (Label (P (V3 x0 y0 z0), V3 x1 y1 z1, V3 x2 y2 z2)) =
  (4, [3], [x0, x1, x2], [y0, y1, y2], [z0, z1, z2])
fromShape (Axis (P (V3 x0 y0 z0), V3 x1 y1 z1)) =
  (5, [2], [x0, x1], [y0, y1], [z0, z1])


data LocationPB =
  LocationPB
  {
    posx' :: Optional 1 (Value Double)
  , posy' :: Optional 2 (Value Double)
  , posz' :: Optional 3 (Value Double)
  , rotw' :: Optional 4 (Value Double)
  , rotx' :: Optional 5 (Value Double)
  , roty' :: Optional 6 (Value Double)
  , rotz' :: Optional 7 (Value Double)
  }
    deriving (Generic, Show)

deriving instance Decode LocationPB

deriving instance Encode LocationPB


toPositionRotation :: LocationPB -> PositionRotation
toPositionRotation LocationPB{..} =
  (
    P
      $ V3
        (fromMaybe 0 $ getField posx')
        (fromMaybe 0 $ getField posy')
        (fromMaybe 0 $ getField posz')
  , Quaternion
      (fromMaybe 0 $ getField rotw')
      $ V3
        (fromMaybe 0 $ getField rotx')
        (fromMaybe 0 $ getField roty')
        (fromMaybe 0 $ getField rotz')
  )


fromPositionRotation :: PositionRotation -> LocationPB
fromPositionRotation (P (V3 px py pz), Quaternion qw (V3 qx qy qz)) =
  LocationPB
  {
    posx' = putField $ Just px
  , posy' = putField $ Just py
  , posz' = putField $ Just pz
  , rotw' = putField $ Just qw
  , rotx' = putField $ Just qx
  , roty' = putField $ Just qy
  , rotz' = putField $ Just qz
  } 
