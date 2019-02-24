{-# LANGUAGE FlexibleContexts  #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}


module InfoVis.Parallel.ProtoBuf.Sink (
  deviceSink
, kafkaSink'
, kafkaSink
) where


import Control.Concurrent.Chan (Chan, readChan)
import Control.Monad (forever, void)
import Control.Monad.Except (MonadError, MonadIO, liftEither)
import Control.Monad.Log (Severity(..), logInfo)
import Data.Bifunctor (first)
import Data.Binary (Binary, encode)
import Data.ByteString.Lazy (toStrict)
import Data.ProtocolBuffers (Encode, encodeMessage)
import Data.Serialize (runPut)
import InfoVis (LoggerIO, SeverityLog, guardIO)
import Network.Kafka.Producer (makeKeyedMessage)
import Network.UI.Kafka (TopicConnection(..), rawProducerLoop)


deviceSink :: (MonadError String m, MonadIO m, SeverityLog m, Show a)
           => Chan a
           -> m ()
deviceSink channel =
  void
    . forever
    . void
    . guardIO
    $ readChan channel


kafkaSink' :: (MonadError String m, MonadIO m, SeverityLog m, Binary a, Show a)
           => LoggerIO
           -> Chan a
           -> TopicConnection
           -> m ()
kafkaSink' logger channel topicConnection@TopicConnection{..} =
  do
    let
      (host, port) = address
    logInfo $ "Opening Kafka topic " ++ topic ++ " on " ++ host ++ ":" ++ show port ++ " with client " ++ client ++ " . . ."
    (_, loop) <-
      guardIO
        . rawProducerLoop
          topicConnection
          (makeKeyedMessage "glut")
        $ do
          buffer <- readChan channel
          logger Debug $ "Write Kafka: " ++ show buffer
          return [toStrict $ encode buffer]
    liftEither
      .   first show
      =<< guardIO loop
    logInfo $ "Closing connection to Kafka topic " ++ topic ++ " on " ++ host ++ ":" ++ show port ++ " . . ."


kafkaSink :: (MonadError String m, MonadIO m, SeverityLog m, Encode a, Show a)
          => LoggerIO
          -> Chan a
          -> TopicConnection
          -> m ()
kafkaSink logger channel topicConnection@TopicConnection{..} =
  do
    let
      (host, port) = address
    logInfo $ "Opening Kafka topic " ++ topic ++ " on " ++ host ++ ":" ++ show port ++ " with client " ++ client ++ " . . ."
    (_, loop) <-
      guardIO
        . rawProducerLoop
          topicConnection
          (makeKeyedMessage "protobuf")
        $ do
          buffer <- readChan channel
          logger Debug $ "Write Kafka: " ++ show buffer
          return [runPut $ encodeMessage buffer]
    liftEither
      .   first show
      =<< guardIO loop
    logInfo $ "Closing connection to Kafka topic " ++ topic ++ " on " ++ host ++ ":" ++ show port ++ " . . ."
