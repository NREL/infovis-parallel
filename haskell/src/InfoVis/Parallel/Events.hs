{-# LANGUAGE DeriveGeneric    #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE Rank2Types       #-}
{-# LANGUAGE RecordWildCards  #-}


module InfoVis.Parallel.Events (
  forwardEvents
) where


import Control.Concurrent.Chan (Chan, newChan, writeChan)
import Control.Concurrent.MVar (MVar, newMVar, putMVar, takeMVar)
import Control.Concurrent.MVar.Util (modifyMVar')
import Control.Monad (unless, void)
import Control.Monad.Except (MonadError, MonadIO, liftEither)
import Control.Monad.Log (Severity(..), logInfo)
import Data.Aeson.Types (FromJSON, ToJSON)
import Data.Bifunctor (first)
import Data.Default (Default(..))
import Data.Yaml (decodeFileEither)
import GHC.Generics (Generic)
import InfoVis (LoggerIO, SeverityLog, forkLoggedIO, guardIO, logIO, makeLogger)
import InfoVis.Parallel.Events.Types (Behave(..), Visualization)
import InfoVis.Parallel.ProtoBuf (Request)
import InfoVis.Parallel.ProtoBuf.Sink (kafkaSink)
import Network.UI.Kafka (Sensor, TopicConnection(..), consumerLoop)

import qualified InfoVis.Parallel.Events.ButtonFrame as E (ButtonFrame)
import qualified InfoVis.Parallel.Events.KeyFrame as E (KeyFrame)
import qualified InfoVis.Parallel.Events.KeyMovement as E (KeyMovement)
import qualified InfoVis.Parallel.Events.Location as E (OffsetLocation, ToolLocation, ViewerLocation)
import qualified InfoVis.Parallel.Events.Typing as E (Typing)


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
    ButtonFrame    E.ButtonFrame
  | KeyFrame       E.KeyFrame
  | KeyMovement    E.KeyMovement
  | OffsetLocation E.OffsetLocation
  | ToolLocation   E.ToolLocation
  | Typing         E.Typing
  | ViewerLocation E.ViewerLocation
    deriving (Eq, Generic, Read, Show)

instance FromJSON Behavior

instance ToJSON Behavior

instance Behave Behavior where

  initialize (ButtonFrame    behavior) = initialize behavior
  initialize (KeyFrame       behavior) = initialize behavior
  initialize (KeyMovement    behavior) = initialize behavior
  initialize (ToolLocation   behavior) = initialize behavior
  initialize (Typing         behavior) = initialize behavior
  initialize (ViewerLocation behavior) = initialize behavior
  initialize (OffsetLocation behavior) = initialize behavior

  behave (ButtonFrame    behavior) = behave behavior
  behave (KeyFrame       behavior) = behave behavior
  behave (KeyMovement    behavior) = behave behavior
  behave (ToolLocation   behavior) = behave behavior
  behave (Typing         behavior) = behave behavior
  behave (ViewerLocation behavior) = behave behavior
  behave (OffsetLocation behavior) = behave behavior


forwardEvents :: (MonadError String m, MonadIO m, SeverityLog m)
              => (String, Int)
              -> String
              -> String
              -> [FilePath]
              -> m ()
forwardEvents address client topic configurations =
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
    guardIO
      $ mapM_ (modifyMVar' visualizationMVar . initialize . snd) handlers
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
                    $ do
                      logger Debug $ "Sending request: " ++ show request
                      writeChan requestChannel request
              |
                (sensor', behavior) <- handlers
              , sensor == sensor'
              ]
    liftEither
      .   first show
      =<< guardIO loop
    logInfo $ "Closing connection to Kafka topic " ++ topic ++ " on " ++ host ++ ":" ++ show port ++ " . . ."
