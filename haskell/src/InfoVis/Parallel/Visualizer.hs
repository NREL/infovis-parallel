{-# LANGUAGE CPP              #-}
{-# LANGUAGE DeriveGeneric    #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RecordWildCards  #-}


module InfoVis.Parallel.Visualizer (
  visualizeBuffers
) where


import Control.Concurrent (threadDelay)
import Control.Concurrent.Chan (Chan, newChan, readChan, writeChan)
import Control.Concurrent.MVar (MVar, newEmptyMVar, newMVar, putMVar, readMVar, swapMVar, takeMVar, tryPutMVar, tryTakeMVar)
import Control.Lens.Getter ((^.))
import Control.Lens.Lens ((&))
import Control.Lens.Setter ((.~))
import Control.Monad (forever, void, when)
import Control.Monad.Except (MonadError, MonadIO, liftEither)
import Control.Monad.Log (Severity(..), logDebug, logInfo)
import Data.Aeson.Types (FromJSON, ToJSON)
import Data.Default (def)
import Data.Maybe (isJust)
import Data.ProtocolBuffers (decodeMessage)
import Data.Serialize (runGet)
import Data.Yaml (decodeFileEither)
import GHC.Generics (Generic)
import Graphics.OpenGL.Util.Setup (dlpViewerDisplay, setup)
import Graphics.OpenGL.Util.Types (Viewer)
import Graphics.Rendering.OpenGL (($=!))
import Graphics.UI.GLUT (mainLoop)
import Graphics.UI.GLUT.Callbacks.Global (IdleCallback, idleCallback)
import Graphics.UI.GLUT.Window (postRedisplay)
import InfoVis (LogChannel, LoggerIO, SeverityLog, guardIO, forkLoggedIO, forkLoggedOS, logIO, makeLogger)
import InfoVis.Parallel.NewTypes (PositionRotation)
import InfoVis.Parallel.ProtoBuf (Request, Response)
import InfoVis.Parallel.Rendering.Buffers (ShapeBuffer)
import InfoVis.Parallel.Rendering.Frames (Manager, createManager, currentFrame, delete, draw, insert, prepare, program, reset)
import InfoVis.Parallel.Rendering.Selector (createSelector, drawSelector, prepareSelector)
import InfoVis.Parallel.Rendering.Text (drawText)
import Linear.Affine (Point(..))
import Linear.Quaternion (Quaternion(..))
import Linear.V3 (V3(..))
import Network.UI.Kafka (TopicConnection)

import qualified Data.ByteString as BS (readFile)
import qualified InfoVis.Parallel.ProtoBuf as P (delete, display, frameShow, frameShown, reset, toolSet, upsert, viewSet)

#ifdef INFOVIS_SWAP_GROUP
import Graphics.OpenGL.Functions (joinSwapGroup)
#endif


data Configuration =
  Configuration
  {
    viewer :: Viewer Double
  , kafka  :: Maybe TopicConnection
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
        sequence_
          [
            do
              logInfo $ "Reading protocol buffers from " ++ show file ++ " . . ."
              request <-
                liftEither
                  =<< guardIO (runGet decodeMessage <$> BS.readFile file)
              guardIO
                $ writeChan requestChannel request
          |
            file <- bufferFiles
          ]
        void
          . guardIO
          . forever
          $ do
            threadDelay 1000
            writeChan requestChannel def 
        return False

    void
      . forkLoggedIO logChannel
      $ do
        void
          . forever
          $ do
              response <-
                guardIO
                  $ readChan responseChannel
              logDebug $ "Response: " ++ show response
        return False

    visualize viewer debug logChannel requestChannel responseChannel

    logger


data Graphics =
  Graphics
  {
    startRef    :: MVar ()
  , lockRef     :: MVar ()
  , managerRef  :: MVar Manager
  , selectorRef :: MVar ShapeBuffer
  , povRef      :: MVar PositionRotation
  , toolRef     :: MVar PositionRotation
  , textRef     :: MVar String
  }


initialize :: IO Graphics
initialize =
  do
    startRef    <- newEmptyMVar
    lockRef     <- newEmptyMVar 
    managerRef  <- newEmptyMVar
    selectorRef <- newEmptyMVar
    povRef      <- newMVar (P $ V3 3 2 10, Quaternion 0 $ V3 0 1 0)
    toolRef     <- newMVar (P $ V3 0 0  0, Quaternion 0 $ V3 0 1 0)
    textRef     <- newMVar ""
    return Graphics{..}
 

visualize :: (MonadError String m, MonadIO m, SeverityLog m)
          => Viewer Double
          -> Bool
          -> LogChannel
          -> Chan Request
          -> Chan Response
          -> m ()
visualize viewer' debug logChannel requestChannel responseChannel =
  do

    graphics <- guardIO initialize

    void
      . forkLoggedIO logChannel
      $ do
        guardIO $ takeMVar $ startRef graphics
        apply graphics requestChannel
        return False

    logInfo "Forking OpenGL . . ."
    void
      . forkLoggedOS logChannel
      . guardIO
      $ do
        display (logIO logChannel) debug viewer' graphics responseChannel
        return True


apply :: (MonadError String m, MonadIO m, SeverityLog m)
      => Graphics
      -> Chan Request
      -> m ()
apply Graphics{..} requestChannel =
  let
    conditionally f g x = if f x then g x else id
    onlyJust v = maybe (return ()) (void . swapMVar v)
  in
    guardIO
      . forever
      $ do
        request <- readChan requestChannel
        void $ takeMVar lockRef
        manager <- readMVar managerRef
        void
          . swapMVar managerRef
          . delete                                 (request ^. P.delete   )
          . insert                                 (request ^. P.upsert   )
          . conditionally id     (const reset)     (request ^. P.reset    )
          . conditionally (/= 0) (currentFrame .~) (request ^. P.frameShow)
          $ manager
        putMVar lockRef ()
        onlyJust povRef  $ request ^. P.viewSet
        onlyJust toolRef $ request ^. P.toolSet
        onlyJust textRef $ request ^. P.display


display :: LoggerIO
        -> Bool
        -> Viewer Double
        -> Graphics
        -> Chan Response
        -> IO ()
display logger debug viewer' Graphics{..} responseChannel =
  do

    logger Debug "Initializing OpenGL . . ."
    dlp <-
      setup 
        (if debug then Just (logger Debug . show) else Nothing)
        "InfoVis Parallel"
        "InfoVis Parallel"
        viewer'

    logger Debug "Creating array buffer manager . . ."
    createManager
      >>= prepare
      >>= putMVar managerRef
    createSelector
      .   program
      <$> readMVar managerRef
      >>= prepareSelector (P (V3 0 0 0), Quaternion 1 (V3 0 0 0))
      >>= putMVar selectorRef
    lockRef `putMVar` ()

    logger Debug "Setting up display . . ."
    dlpViewerDisplay dlp viewer' (readMVar povRef)
      $ do
        readMVar managerRef  >>= draw
        readMVar selectorRef >>= drawSelector
        readMVar textRef     >>= drawText

    idleCallback $=! Just (idle Graphics{..} responseChannel)

#ifdef INFOVIS_SWAP_GROUP
    logger Debug "Joining swap group . . ."
    void
      $  maybe (return False) joinSwapGroup useSwapGroup
#endif

    logger Debug "Starting main loop . . ."
    mainLoop


idle :: Graphics
     -> Chan Response
     -> IdleCallback
idle Graphics{..} responseChannel =
  do
    void
      $ tryPutMVar startRef ()
    tool <- readMVar toolRef
    lock <- tryTakeMVar lockRef
    when (isJust lock)
      $ do
        void
          $   readMVar managerRef
          >>= prepare
          >>= swapMVar managerRef
        void
          $   readMVar selectorRef
          >>= prepareSelector tool
          >>= swapMVar selectorRef
        lockRef `putMVar` ()
    frame <- (^. currentFrame) <$> readMVar managerRef
    let
      response = def & P.frameShown .~ frame
    writeChan responseChannel response
    postRedisplay Nothing
