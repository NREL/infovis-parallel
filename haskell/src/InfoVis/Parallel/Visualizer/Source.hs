{-# LANGUAGE FlexibleContexts #-}


module InfoVis.Parallel.Visualizer.Source (
  filesSource
, fileSource
, kafkaSource
, waitForever
) where


import Control.Concurrent (threadDelay)
import Control.Concurrent.Chan (Chan, writeChan)
import Control.Monad (forever, void)
import Control.Monad.Except (MonadError, MonadIO, liftEither)
import Control.Monad.Log (logInfo)
import Data.Default (def)
import Data.ProtocolBuffers (decodeMessage)
import Data.Serialize (runGet)
import InfoVis (SeverityLog, guardIO)
import InfoVis.Parallel.ProtoBuf (Request)
import Network.UI.Kafka (TopicConnection)

import qualified Data.ByteString as BS (readFile)


filesSource :: (MonadError String m, MonadIO m, SeverityLog m)
            => Chan Request
            -> [FilePath]
            -> m ()
filesSource requestChannel =
  mapM_
    $ fileSource requestChannel


fileSource :: (MonadError String m, MonadIO m, SeverityLog m)
           => Chan Request
           -> FilePath
           -> m ()
fileSource requestChannel bufferFile =
  do
    logInfo $ "Reading protocol buffers from " ++ show bufferFile ++ " . . ."
    request <-
      liftEither
        =<< guardIO (runGet decodeMessage <$> BS.readFile bufferFile)
    guardIO
      $ writeChan requestChannel request


kafkaSource :: (MonadError String m, MonadIO m, SeverityLog m)
            => Chan Request
            -> TopicConnection
            -> m ()
kafkaSource _requestChannel _topicConnection =
  return ()


waitForever :: (MonadError String m, MonadIO m, SeverityLog m)
            => Chan Request
            -> m ()
waitForever requestChannel =
  void
    . guardIO
    . forever
    $ do
      threadDelay 1000
      writeChan requestChannel def 
