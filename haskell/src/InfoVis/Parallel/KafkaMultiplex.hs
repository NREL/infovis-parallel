{-# LANGUAGE DeriveGeneric    #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RecordWildCards  #-}


module InfoVis.Parallel.KafkaMultiplex (
  multiplexKafka



, Device(..)
, Behavior(..)
) where


import Control.Concurrent.Chan (Chan, newChan, writeChan)
import Control.Concurrent.MVar (MVar, newMVar, putMVar, takeMVar)
import Control.Lens.Lens ((&))
import Control.Lens.Setter ((?~))
import Control.Monad (void)
import Control.Monad.Except (MonadError, MonadIO, liftEither)
import Control.Monad.Log (Severity(..), logInfo)
import Data.Aeson.Types (FromJSON, ToJSON)
import Data.Bifunctor (first)
import Data.Default (Default(..))
import Data.Yaml (decodeFileEither)
import GHC.Generics (Generic)
import InfoVis (LoggerIO, SeverityLog, forkLoggedIO, guardIO, logIO, makeLogger)
import InfoVis.Parallel.ProtoBuf (Request)
import InfoVis.Parallel.ProtoBuf.Sink (kafkaSink)
import Network.UI.Kafka (Sensor, TopicConnection(..), consumerLoop)
import Network.UI.Kafka.Types (Event(..))

import qualified InfoVis.Parallel.ProtoBuf as P (display)


data Visualization =
  Visualization
  {
    shown :: String
  }
   deriving (Eq, Ord, Read, Show)

instance Default Visualization where
  def = Visualization def


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
                  writeChan requestChannel request
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
    TextBehavior
  | NullBehavior
    deriving (Eq, Generic, Read, Show)

instance FromJSON Behavior

instance ToJSON Behavior


behave :: Behavior
       -> Event
       -> Visualization
       -> (Visualization, Request)

behave TextBehavior KeyEvent{..} visualization@Visualization{..} =
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

behave _ _ visualization = (visualization, def)
