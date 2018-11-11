{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE DeriveAnyClass        #-}
{-# LANGUAGE DeriveGeneric         #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE RecordWildCards       #-}


module InfoVis.Parallel.ProtoBuf (
  Request
, frameShow
, reset
, upsert
, delete
, viewSet
, toolSet
, Response
, frameShown
, message
, hover
, unhover
, select
, deselect
, viewGet
, toolGet
, depressed
, pressed
, released
, analog
, Geometry(..)
, Shape(..)
) where


import Control.Lens.Getter ((^.))
import Control.Lens.Lens (Lens', (&), lens)
import Control.Lens.Setter ((.~))
import Control.Lens.Tuple (_1, _2, _3, _4, _5)
import Control.Monad (guard)
import Data.Aeson ((.=), (.:?))
import Data.Aeson.Types (FromJSON(..), ToJSON(..), object, withObject)
import Data.Bits (Bits, (.|.), (.&.), shift)
import Data.Default (Default(..))
import Data.Int (Int32)
import Data.List.Split (splitPlaces)
import Data.Maybe (fromMaybe)
import Data.ProtocolBuffers (Decode, Encode, Message, Optional, Packed, Repeated, Value, decodeMessage, encodeMessage, getField, putField)
import Data.Serialize (runGetLazy, runPutLazy)
import GHC.Generics (Generic)
import InfoVis.Parallel.NewTypes (Buttons, Color, Displacement, Frame, Identifier, Position, PositionRotation)
import Linear.Affine (Point(..))
import Linear.Quaternion (Quaternion(..))
import Linear.V3 (V3(..))
import Network.WebSockets (DataMessage(..), WebSocketsData(..))

import qualified Data.Text.Lazy as T (unpack)


data Request =
  Request
  {
    show'    :: Optional 1 (Value   Frame     )
  , reset'   :: Optional 2 (Value   Bool      )
  , upsert'  :: Repeated 3 (Message GeometryPB)
  , delete'  :: Packed   4 (Value   Identifier)
  , viewloc' :: Optional 5 (Message LocationPB)
  , toolloc' :: Optional 6 (Message LocationPB)
  }
    deriving (Generic, Show)

instance Default Request where
  def =
    Request
    {
      show'    = putField def
    , reset'   = putField def
    , upsert'  = putField def
    , delete'  = putField def
    , viewloc' = putField def
    , toolloc' = putField def
    }

instance FromJSON Request where
  parseJSON =
    withObject "Request"
      $ \v ->
      do
        show'    <- putField                                             <$> v .:? "frame"
        reset'   <- putField                                             <$> v .:? "reset"
        upsert'  <- putField . fmap fromGeometry         . fromMaybe def <$> v .:? "upsert"
        delete'  <- putField .                             fromMaybe def <$> v .:? "delete"
        viewloc' <- putField . fmap fromPositionRotation                 <$> v .:? "viewloc"
        toolloc' <- putField . fmap fromPositionRotation                 <$> v .:? "toolloc"
        return Request{..}

instance ToJSON Request where
  toJSON Request{..} =
    object
     . maybe id ((:) . ("frame"   .=)) (                       getField show'   )
     . maybe id ((:) . ("reset"   .=)) (                       getField reset'  )
     . option           "upsert"       (toGeometry         <$> getField upsert' )
     . option           "delete"       (                       getField delete' )
     . maybe id ((:) . ("viewloc" .=)) (toPositionRotation <$> getField viewloc')
     $ maybe id ((:) . ("toolloc" .=)) (toPositionRotation <$> getField toolloc')
       []
    where
      option s v = if null v then id else ((s .= v) :)

instance Decode Request

instance Encode Request

instance WebSocketsData Request where
  fromDataMessage (Text _ _) = def
  fromDataMessage (Binary x) = fromLazyByteString x
  fromLazyByteString = either error id . runGetLazy decodeMessage
  toLazyByteString = runPutLazy . encodeMessage


frameShow :: Lens' Request Frame
frameShow =
  lens
    (fromMaybe def . getField . show')
    (\s x -> s {show' = putField $ Just x})


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
    (fmap toPositionRotation . getField . (viewloc' :: Request -> Optional 5 (Message LocationPB)))
    (\s x -> (s :: Request) {viewloc' = putField $ fromPositionRotation <$> x})


toolSet :: Lens' Request (Maybe PositionRotation)
toolSet =
  lens
    (fmap toPositionRotation . getField . (toolloc' :: Request -> Optional 6 (Message LocationPB)))
    (\s x -> (s :: Request) {toolloc' = putField $ fromPositionRotation <$> x})


data Response =
  Response
  {
    shown'     :: Optional  1 (Value   Frame     )
  , message'   :: Optional  2 (Value   String    )
  , hover'     :: Packed    3 (Value   Identifier)
  , unhover'   :: Packed    4 (Value   Identifier)
  , select'    :: Packed    5 (Value   Identifier)
  , deselect'  :: Packed    6 (Value   Identifier)
  , viewloc'   :: Optional  7 (Message LocationPB)
  , toolloc'   :: Optional  8 (Message LocationPB)
  , depressed' :: Optional  9 (Value   Buttons   )
  , pressed'   :: Optional 10 (Value   Buttons   )
  , released'  :: Optional 11 (Value   Buttons   )
  , analog'    :: Packed   12 (Value   Double    )
  }
    deriving (Generic, Show)

instance Default Response where
  def = 
    Response
    {
      shown'     = putField def
    , message'   = putField def
    , hover'     = putField def
    , unhover'   = putField def
    , select'    = putField def
    , deselect'  = putField def
    , viewloc'   = putField def
    , toolloc'   = putField def
    , depressed' = putField def
    , pressed'   = putField def
    , released'  = putField def
    , analog'    = putField def
    }

instance FromJSON Response where
  parseJSON =
    withObject "Response"
      $ \v ->
      do
        shown'     <- putField                             <$> v .:? "frame"
        message'   <- putField                             <$> v .:? "message"
        hover'     <- putField . fromMaybe def             <$> v .:? "hover"
        unhover'   <- putField . fromMaybe def             <$> v .:? "unhover"
        select'    <- putField . fromMaybe def             <$> v .:? "select"
        deselect'  <- putField . fromMaybe def             <$> v .:? "deselect"
        viewloc'   <- putField . fmap fromPositionRotation <$> v .:? "viewloc"
        toolloc'   <- putField . fmap fromPositionRotation <$> v .:? "toolloc"
        depressed' <- putField                             <$> v .:? "depressed"
        pressed'   <- putField                             <$> v .:? "pressed"
        released'  <- putField                             <$> v .:? "released"
        analog'    <- putField . fromMaybe def             <$> v .:? "analog"
        return Response{..}

instance ToJSON Response where
  toJSON Response{..} =
    object
     . maybe id ((:) . ("frame"     .=)) (                       getField shown'    )
     . maybe id ((:) . ("message"   .=)) (                       getField message'  )
     . option           "hover"          (                       getField hover'    )
     . option           "unhover"        (                       getField unhover'  )
     . option           "select"         (                       getField select'   )
     . option           "deselect"       (                       getField deselect' )
     . maybe id ((:) . ("viewloc"   .=)) (toPositionRotation <$> getField viewloc'  )
     . maybe id ((:) . ("toolloc"   .=)) (toPositionRotation <$> getField toolloc'  )
     . maybe id ((:) . ("depressed" .=)) (                       getField depressed')
     . maybe id ((:) . ("pressed"   .=)) (                       getField pressed'  )
     . maybe id ((:) . ("released"  .=)) (                       getField released' )
     . option           "analog"         (                       getField analog'   )
     $ []
    where
      option s v = if null v then id else ((s .= v) :)

instance Decode Response

instance Encode Response

instance WebSocketsData Response where
  fromDataMessage (Text _ x) = def & message .~ fmap T.unpack x
  fromDataMessage (Binary x) = fromLazyByteString x
  fromLazyByteString = either error id . runGetLazy decodeMessage
  toLazyByteString = runPutLazy . encodeMessage


frameShown :: Lens' Response Frame
frameShown =
  lens
    (fromMaybe def . getField . shown')
    (\s x -> s {shown' = putField $ Just x})


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
    (fmap toPositionRotation . getField . (viewloc' :: Response -> Optional 7 (Message LocationPB)))
    (\s x -> (s :: Response) {viewloc' = putField $ fromPositionRotation <$> x})


toolGet :: Lens' Response (Maybe PositionRotation)
toolGet =
  lens
    (fmap toPositionRotation . getField . (toolloc' :: Response -> Optional 8 (Message LocationPB)))
    (\s x -> (s :: Response) {toolloc' = putField $ fromPositionRotation <$> x})


depressed :: Lens' Response Buttons
depressed =
  lens
    (maybe def fromIntegral . getField . depressed')
    (\s x -> s {depressed' = putField . Just $ fromIntegral x})


pressed :: Lens' Response Buttons
pressed =
  lens
    (maybe def fromIntegral . getField . pressed')
    (\s x -> s {pressed' = putField . Just $ fromIntegral x})


released :: Lens' Response Buttons
released =
  lens
    (maybe def fromIntegral . getField . released')
    (\s x -> s {released' = putField . Just $ fromIntegral x})


analog :: Lens' Response [Double]
analog =
  lens
    (getField . analog')
    (\s x -> s {analog' = putField x})


data GeometryPB =
  GeometryPB
  {
    fram' :: Optional  1 (Value Frame     )
  , iden' :: Optional  2 (Value Identifier)
  , typp' :: Optional  3 (Value Int32     )
  , mask' :: Optional  4 (Value Int32     )
  , cnts' :: Packed    5 (Value Int32     )
  , posx' :: Packed    6 (Value Double    )
  , posy' :: Packed    7 (Value Double    )
  , posz' :: Packed    8 (Value Double    )
  , size' :: Optional  9 (Value Double    )
  , colr' :: Optional 10 (Value Color     )
  , text' :: Optional 11 (Value String    )
  }
    deriving (Generic, Show)

instance Decode GeometryPB

instance Encode GeometryPB


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
    frame      = fromMaybe def $ getField fram'
    identifier = fromMaybe def $ getField iden'
    mask       = fromMaybe def $ getField mask'
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
    size       = guard (sizeBit  .&. mask /= 0) >> return (fromMaybe def $ getField size')
    color      = guard (colorBit .&. mask /= 0) >> return (fromMaybe def $ getField colr')
    text       = guard (textBit  .&. mask /= 0) >> return (fromMaybe def $ getField text')
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

instance Decode LocationPB

instance Encode LocationPB


toPositionRotation :: LocationPB -> PositionRotation
toPositionRotation LocationPB{..} =
  (
    P
      $ V3
        (fromMaybe def $ getField posx')
        (fromMaybe def $ getField posy')
        (fromMaybe def $ getField posz')
  , Quaternion
      (fromMaybe def $ getField rotw')
      $ V3
        (fromMaybe def $ getField rotx')
        (fromMaybe def $ getField roty')
        (fromMaybe def $ getField rotz')
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
