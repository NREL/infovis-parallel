{-# LANGUAGE DeriveGeneric    #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RecordWildCards  #-}


module InfoVis.Parallel.KafkaMultiplex (
  multiplexKafka
) where


import Control.Concurrent.Chan (Chan, newChan, writeChan)
import Control.Lens.Lens ((&))
import Control.Lens.Setter ((?~))
import Control.Monad (void)
import Control.Monad.Except (MonadError, MonadIO, liftEither)
import Control.Monad.Log (Severity(..), logInfo)
import Data.Aeson.Types (FromJSON, ToJSON)
import Data.Bifunctor (first)
import Data.Default (def)
import Data.Yaml (decodeFileEither)
import GHC.Generics (Generic)
import InfoVis (LoggerIO, SeverityLog, forkLoggedIO, guardIO, logIO, makeLogger)
import InfoVis.Parallel.ProtoBuf (Request)
import InfoVis.Parallel.ProtoBuf.Sink (kafkaSink)
import Network.UI.Kafka (TopicConnection(..), consumerLoop)

import qualified InfoVis.Parallel.ProtoBuf as P (display)


data Device =
  Device
  {
    device     :: TopicConnection
  , transforms :: [()]
  }
    deriving (Eq, Generic, Read, Show)

instance FromJSON Device

instance ToJSON Device


multiplexKafka :: (MonadError String m, MonadIO m, SeverityLog m)
               => (String, Int)
               -> String
               -> String
               -> [FilePath]
               -> m ()
multiplexKafka address client topic configurations =
  do

    (logChannel, logger) <- makeLogger

    requestChannel  <- guardIO newChan

    sequence_
      [
        void
          . forkLoggedIO logChannel
          $ do
            createDevice (logIO logChannel) requestChannel configuration
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
             -> FilePath
             -> m ()
createDevice logger requestChannel configuration =
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
            writeChan requestChannel
              $ def
              & P.display ?~ sensor
    liftEither
      .   first show
      =<< guardIO loop
    logInfo $ "Closing connection to Kafka topic " ++ topic ++ " on " ++ host ++ ":" ++ show port ++ " . . ."
