{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RecordWildCards  #-}


module InfoVis.Parallel.ProtoBuf.Source (
  filesSource
, fileSource
, kafkaSource
, waitForever
) where


import Control.Concurrent (threadDelay)
import Control.Concurrent.Chan (Chan, writeChan)
import Control.Monad (forever, void)
import Control.Monad.Except (MonadError, MonadIO, liftEither)
import Control.Monad.Log (Severity(..), logInfo)
import Data.Bifunctor (first)
import Data.Default (Default(..))
import Data.ProtocolBuffers (Decode, decodeMessage)
import Data.Serialize (runGet)
import InfoVis (LoggerIO, SeverityLog, guardIO)
import Network.Kafka.Protocol (KafkaBytes(..), Message(..), Value(..))
import Network.UI.Kafka (TopicConnection(..), rawConsumerLoop)

import qualified Data.ByteString as BS (readFile)


filesSource :: (MonadError String m, MonadIO m, SeverityLog m, Decode a)
            => Chan a
            -> [FilePath]
            -> m ()
filesSource channel =
  mapM_
    $ fileSource channel


fileSource :: (MonadError String m, MonadIO m, SeverityLog m, Decode a)
           => Chan a
           -> FilePath
           -> m ()
fileSource channel file =
  do
    logInfo $ "Reading protocol buffers from " ++ show file ++ " . . ."
    buffer <-
      liftEither
        =<< guardIO (runGet decodeMessage <$> BS.readFile file)
    guardIO
      $ writeChan channel buffer


kafkaSource :: (MonadError String m, MonadIO m, SeverityLog m, Decode a, Show a)
            => LoggerIO
            -> Chan a
            -> TopicConnection
            -> m ()
kafkaSource logger channel topicConnection@TopicConnection{..} =
  do
    let
      (host, port) = address
    logInfo $ "Opening Kafka topic " ++ topic ++ " on " ++ host ++ ":" ++ show port ++ " with client " ++ client ++ " . . ."
    (_, loop) <-
      guardIO
        . rawConsumerLoop topicConnection
            (
              \message ->
                let
                  (_, _, _, _, Value (Just (KBytes bytes)) ) = _messageFields message
                in
                  either error id . runGet decodeMessage $ bytes
            )
          $ \buffer ->
            do
              logger Debug $ "Read Kafka: " ++ show buffer
              writeChan channel buffer
    liftEither
      .   first show
      =<< guardIO loop
    logInfo $ "Closing connection to Kafka topic " ++ topic ++ " on " ++ host ++ ":" ++ show port ++ " . . ."


waitForever :: (MonadError String m, MonadIO m, SeverityLog m, Default a)
            => Chan a
            -> m ()
waitForever channel =
  void
    . guardIO
    . forever
    $ do
      threadDelay maxBound
      writeChan channel def 
