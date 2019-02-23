{-# LANGUAGE CPP              #-}
{-# LANGUAGE DeriveGeneric    #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RecordWildCards  #-}


module InfoVis.Parallel.Visualizer (
  visualizeBuffers
) where


import Control.Concurrent.Chan (newChan)
import Control.Monad (void)
import Control.Monad.Except (MonadError, MonadIO, liftEither)
import Control.Monad.Log (logInfo)
import Data.Aeson.Types (FromJSON, ToJSON)
import Data.Yaml (decodeFileEither)
import GHC.Generics (Generic)
import Graphics.OpenGL.Util.Types (Viewer)
import InfoVis (SeverityLog, guardIO, forkLoggedIO, logIO, makeLogger)
import InfoVis.Parallel.ProtoBuf.Sink (deviceSink)
import InfoVis.Parallel.ProtoBuf.Source (filesSource, kafkaSource, waitForever)
import InfoVis.Parallel.Visualizer.Graphics (visualize)
import Network.UI.Kafka (TopicConnection)

#ifdef INFOVIS_SWAP_GROUP
import Graphics.OpenGL.Functions (joinSwapGroup)
#endif


data Configuration =
  Configuration
  {
    viewer    :: Viewer Double
  , requests  :: Maybe TopicConnection
  }
    deriving (Eq, Generic, Read, Show)

instance FromJSON Configuration

instance ToJSON Configuration


visualizeBuffers :: (MonadError String m, MonadIO m, SeverityLog m)
                 => FilePath
                 -> Bool
                 -> [FilePath]
                 -> m ()
visualizeBuffers configurationFile debug bufferFiles =
  do

    (logChannel, logger) <- makeLogger

    requestChannel  <- guardIO newChan
    responseChannel <- guardIO newChan

    logInfo $ "Reading configuration from " ++ show configurationFile ++ " . . ."
    Configuration{..} <-
      liftEither . either (Left . show) Right
        =<< guardIO (decodeFileEither configurationFile)

    void
      . forkLoggedIO logChannel
      $ do
        filesSource requestChannel bufferFiles
        maybe waitForever (flip . kafkaSource $ logIO logChannel) requests requestChannel
        return False

    void
      . forkLoggedIO logChannel
      $ do
        deviceSink responseChannel
        return False

    visualize viewer debug logChannel requestChannel responseChannel

    logger
