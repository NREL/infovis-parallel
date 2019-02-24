{-# LANGUAGE DeriveGeneric    #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RecordWildCards  #-}


module InfoVis.Parallel.KafkaMultiplex (
  Device(..)
, Behavior(..)
, multiplexKafka
) where


import Control.Concurrent.Chan (Chan, newChan, writeChan)
import Control.Concurrent.MVar (MVar, newMVar, putMVar, takeMVar)
import Control.Lens.Lens ((&))
import Control.Lens.Setter ((.~), (?~))
import Control.Monad (unless, void)
import Control.Monad.Except (MonadError, MonadIO, liftEither)
import Control.Monad.Log (Severity(..), logInfo)
import Data.Aeson.Types (FromJSON, ToJSON)
import Data.Bifunctor (bimap, first)
import Data.Default (Default(..))
import Data.Yaml (decodeFileEither)
import GHC.Generics (Generic)
import InfoVis (LoggerIO, SeverityLog, forkLoggedIO, guardIO, logIO, makeLogger)
import InfoVis.Parallel.NewTypes (Frame, PositionRotation)
import InfoVis.Parallel.ProtoBuf (Request)
import InfoVis.Parallel.ProtoBuf.Sink (kafkaSink)
import Linear.Affine (Point(..), (.+^))
import Linear.Conjugate (conjugate)
import Linear.Quaternion (Quaternion(..), axisAngle)
import Linear.V3 (V3(..))
import Linear.Vector ((*^), zero)
import Network.UI.Kafka (Sensor, TopicConnection(..), consumerLoop)
import Network.UI.Kafka.Types (Event(..), Modifiers(..),  SpecialKey(..))

import qualified InfoVis.Parallel.ProtoBuf as P (display, frameShow, toolSet, viewSet)


data Visualization =
  Visualization
  {
    frame  :: Frame
  , shown  :: String
  , viewer :: PositionRotation
  , tool   :: PositionRotation
  }
   deriving (Eq, Ord, Read, Show)

instance Default Visualization where
  def =
    Visualization
    {
      frame = 1
    , shown  = ""
    , viewer = (P $ V3 3 2 10, Quaternion 0 $ V3 0 1 0)
    , tool   = (P $ V3 0 0  0, Quaternion 0 $ V3 0 1 0)
    }


multiplexKafka :: (MonadError String m, MonadIO m, SeverityLog m)
               => (String, Int)
               -> String
               -> String
               -> [FilePath]
               -> m ()
multiplexKafka address client topic configurations =
  do

    visualizationMVar <- guardIO $ newMVar def

    (logChannel, logger) <- makeLogger

    requestChannel  <- guardIO newChan

    sequence_
      [
        void
          . forkLoggedIO logChannel
          $ do
            createDevice (logIO logChannel) requestChannel visualizationMVar configuration
            return False
      |
        configuration <- configurations
      ]

    void
      . forkLoggedIO logChannel
      $ do
        kafkaSink (logIO logChannel) requestChannel TopicConnection{..}
        return False

    logger


createDevice :: (MonadError String m, MonadIO m, SeverityLog m)
             => LoggerIO
             -> Chan Request
             -> MVar Visualization
             -> FilePath
             -> m ()
createDevice logger requestChannel visualizationMVar configuration =
  do
    logInfo $ "Reading device configuration from " ++ show configuration ++ " . . ."
    Device{..}  <-
      liftEither . either (Left . show) Right
        =<< guardIO (decodeFileEither configuration)
    let
      TopicConnection{..} = device
      (host, port) = address
    logInfo $ "Opening Kafka topic " ++ topic ++ " on " ++ host ++ ":" ++ show port ++ " with client " ++ client ++ " . . ."
    (_, loop) <-
      guardIO
        .  consumerLoop device
        $ \sensor event ->
          do
            logger Debug $ "Received from sensor " ++ sensor ++ ": " ++ show event
            sequence_
              [
                do
                  visualization <- takeMVar visualizationMVar
                  let
                    (visualization', request) = behave behavior event visualization
                  putMVar visualizationMVar visualization'   
                  unless (visualization == visualization')
                    $ writeChan requestChannel request
              |
                (sensor', behavior) <- handlers
              , sensor == sensor'
              ]
    liftEither
      .   first show
      =<< guardIO loop
    logInfo $ "Closing connection to Kafka topic " ++ topic ++ " on " ++ host ++ ":" ++ show port ++ " . . ."


data Device =
  Device
  {
    device  :: TopicConnection
  , handlers :: [(Sensor, Behavior)]
  }
    deriving (Eq, Generic, Read, Show)

instance FromJSON Device

instance ToJSON Device


data Behavior =
    Typing
  | KeyFrame
    {
      nextFrame     :: Either SpecialKey Char
    , previousFrame :: Either SpecialKey Char
    , setFrame      :: [(Frame, Either SpecialKey Char)]
    }
  | KeyMovement
    {
      viewerModifiers        :: Maybe Modifiers
    , toolModifiers          :: Maybe Modifiers
    , deltaViewerPosition    :: Double
    , deltaToolPosition      :: Double
    , deltaRotation          :: Double
    , moveRightward          :: Either SpecialKey Char
    , moveLeftward           :: Either SpecialKey Char
    , moveForward            :: Either SpecialKey Char
    , moveBackward           :: Either SpecialKey Char
    , moveUpward             :: Either SpecialKey Char
    , moveDownward           :: Either SpecialKey Char
    , rotateForward          :: Either SpecialKey Char
    , rotateBackward         :: Either SpecialKey Char
    , rotateClockwise        :: Either SpecialKey Char
    , rotateCounterclockwise :: Either SpecialKey Char
    , rotateRightward        :: Either SpecialKey Char
    , rotateLeftward         :: Either SpecialKey Char
    }
    deriving (Eq, Generic, Read, Show)

instance FromJSON Behavior

instance ToJSON Behavior


behave :: Behavior
       -> Event
       -> Visualization
       -> (Visualization, Request)

behave Typing KeyEvent{..} visualization@Visualization{..} =
  let
    text =
      if key == '\n'
        then ""
        else shown ++ [key]
  in
    (
      visualization
      {
        shown = text
      }
    , def & P.display ?~ text
    )

behave keyFrame'@KeyFrame{} KeyEvent{..} visualization =
  keyFrame keyFrame' (Right key) visualization
behave keyFrame'@KeyFrame{} SpecialKeyEvent{..} visualization =
  keyFrame keyFrame' (Left specialKey) visualization

behave keyMovement'@KeyMovement{} KeyEvent{..} visualization =
  keyMovement keyMovement' (Right key) modifiers visualization
behave keyMovement'@KeyMovement{} SpecialKeyEvent{..} visualization =
  keyMovement keyMovement' (Left specialKey) modifiers visualization

behave _ _ visualization = (visualization, def)


keyMovement :: Behavior
            -> Either SpecialKey Char
            -> Maybe Modifiers
            -> Visualization
            -> (Visualization, Request)
keyMovement KeyMovement{..} key' modifiers' visualization@Visualization{..} =
  let
    motion =
      head' zero
        $ snd
        <$> filter ((key' ==) . fst)
        [
          (moveRightward, V3   1   0   0 )
        , (moveLeftward , V3 (-1)  0   0 )
        , (moveForward  , V3   0   0 (-1))
        , (moveBackward , V3   0   0   1 )
        , (moveUpward   , V3   0   1   0 )
        , (moveDownward , V3   0 (-1)  0 )
        ]
    rotation =
      head' (Quaternion 1 zero)
        $ snd
        <$> filter ((key' ==) . fst)
        [
          (rotateForward         , V3 1 0 0 `axisAngle`   deltaRotation )
        , (rotateBackward        , V3 1 0 0 `axisAngle` (-deltaRotation))
        , (rotateClockwise       , V3 0 1 0 `axisAngle`   deltaRotation )
        , (rotateCounterclockwise, V3 0 1 0 `axisAngle` (-deltaRotation))
        , (rotateLeftward        , V3 0 0 1 `axisAngle`   deltaRotation )
        , (rotateRightward       , V3 0 0 1 `axisAngle` (-deltaRotation))
        ]
    viewer' =
      if modifiers' == viewerModifiers
        then bimap (.+^ (deltaViewerPosition *^ motion)) ((rotation *) . (* conjugate rotation)) viewer
        else viewer
    tool' =
      if modifiers' == toolModifiers
        then bimap (.+^ (deltaToolPosition *^ motion)) ((rotation *) . (* conjugate rotation)) tool
        else tool
  in
   (
      visualization
      {
        viewer = viewer'
      , tool   = tool'
      }
    , def & P.viewSet ?~ viewer'
          & P.toolSet ?~ tool'
    )
keyMovement _ _ _ visualization = (visualization, def)


keyFrame :: Behavior
         -> Either SpecialKey Char
         -> Visualization
         -> (Visualization, Request)
keyFrame KeyFrame{..} key' visualization@Visualization{..} =
  let
    frame'
      | key' == nextFrame     = frame + 1
      | key' == previousFrame = frame - 1
      | otherwise             = head' frame $ fst <$> filter ((key' ==) . snd) setFrame
  in
    (
      visualization
      {
        frame = frame'
      }
    , def & P.frameShow .~ frame'
    )
keyFrame _ _ visualization = (visualization, def)


head' :: a
      -> [a]
      -> a
head' x []      = x
head' _ (x : _) = x
