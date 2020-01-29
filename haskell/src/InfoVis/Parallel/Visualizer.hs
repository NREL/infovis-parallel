{-# LANGUAGE DeriveGeneric    #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RecordWildCards  #-}


module InfoVis.Parallel.Visualizer (
  visualizeBuffers
) where


import Control.Concurrent.Chan (newChan)
import Control.Monad (void)
import Control.Monad.Except (MonadError, MonadIO, liftEither)
import Control.Monad.Log (logDebug,logInfo)
import Data.Aeson.Types (FromJSON, ToJSON)
import Data.Yaml (decodeFileEither)
import GHC.Generics (Generic)
import Graphics.OpenGL.Util.Types (Viewer)
import Graphics.X11.Xlib.Misc (initThreads)
import InfoVis (SeverityLog, guardIO, forkLoggedIO, logIO, makeLogger)
import InfoVis.Parallel.Types (PositionEuler)
import InfoVis.Parallel.ProtoBuf.Sink (deviceSink, kafkaSink')
import InfoVis.Parallel.ProtoBuf.Source (filesSource, kafkaSource, waitForever)
import InfoVis.Parallel.Visualizer.Graphics (visualize)
import Network.UI.Kafka (TopicConnection)


data Configuration =
  Configuration
  {
    viewer        :: Viewer Double
  , initialViewer :: Maybe PositionEuler
  , initialTool   :: Maybe PositionEuler
  , requests      :: Maybe TopicConnection
  , events        :: Maybe TopicConnection
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

    status <- guardIO initThreads
    logDebug $ "X11 initThreads status = " ++ show status ++ "."

    (logChannel, logger) <- makeLogger

    requestChannel  <- guardIO newChan
    responseChannel <- guardIO newChan

    logInfo $ "Reading configuration from " ++ show configurationFile ++ " . . ."
    Configuration{..} <-
      liftEither . either (Left . show) Right
        =<< guardIO (decodeFileEither configurationFile)

    visualize viewer initialViewer initialTool debug logChannel requestChannel responseChannel

    void
      . forkLoggedIO logChannel
      $ do
        filesSource requestChannel bufferFiles
        maybe waitForever (flip . kafkaSource $ logIO logChannel) requests requestChannel
        return False

    void
      . forkLoggedIO logChannel
      $ do
        maybe deviceSink (flip . kafkaSink' $ logIO logChannel) events responseChannel
        return False

    logger
