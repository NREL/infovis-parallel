{-# LANGUAGE CPP              #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RecordWildCards  #-}


module InfoVis.Parallel.Visualizer (
  visualizeBuffers
) where


import Control.Concurrent.Chan (Chan, newChan, readChan, writeChan)
import Control.Concurrent.MVar (MVar, newEmptyMVar, newMVar, putMVar, readMVar, swapMVar, takeMVar, tryPutMVar, tryTakeMVar)
import Control.Lens.Getter ((^.))
import Control.Monad (join, void, when)
import Control.Monad.Except (MonadError, MonadIO, liftEither)
import Control.Monad.Log (Severity(..), logInfo)
import Data.Maybe (isJust)
import Data.ProtocolBuffers (decodeMessage)
import Data.Serialize (runGet)
import Data.Yaml (decodeFileEither)
import Graphics.OpenGL.Util.Setup (dlpViewerDisplay, setup)
import Graphics.OpenGL.Util.Types (Viewer)
import Graphics.Rendering.OpenGL (($=!))
import Graphics.UI.GLUT (mainLoop)
import Graphics.UI.GLUT.Callbacks.Global (IdleCallback, idleCallback)
import Graphics.UI.GLUT.Window (postRedisplay)
import InfoVis (LogChannel, LoggerIO, SeverityLog, guardIO, forkLoggedIO, forkLoggedOS, logIO, makeLogger)
import InfoVis.Parallel.NewTypes (PositionRotation)
import InfoVis.Parallel.ProtoBuf (Request, Response, toolSet, viewSet)
import InfoVis.Parallel.Rendering.Frames (Manager, createManager, delete, draw, insert, prepare, reset, set)
import Linear.Affine (Point(..))
import Linear.Quaternion (Quaternion(..))
import Linear.V3 (V3(..))

import qualified Data.ByteString as BS (readFile)
import qualified InfoVis.Parallel.ProtoBuf as P (delete, frameShow, reset, upsert)

#ifdef INFOVIS_SWAP_GROUP
import Graphics.OpenGL.Functions (joinSwapGroup)
#endif


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

    void
      . forkLoggedIO logChannel
      $ do
        sequence_
          [
            do
              logInfo $ "Reading protocol buffers from " ++ show file ++ " . . ."
              request <- liftEither =<< guardIO (runGet decodeMessage <$> BS.readFile file)
              guardIO $ writeChan requestChannel request
          |
            file <- bufferFiles
          ]
        return False

    visualize configurationFile debug logChannel requestChannel responseChannel

    logger


data Graphics =
  Graphics
  {
    startRef   :: MVar ()
  , lockRef    :: MVar ()
  , managerRef :: MVar Manager
  , povRef     :: MVar PositionRotation
  , toolRef    :: MVar PositionRotation
  }


initialize :: IO Graphics
initialize =
  do
    startRef   <- newEmptyMVar
    lockRef    <- newEmptyMVar 
    managerRef <- newEmptyMVar
    povRef     <- newMVar (P $ V3 3 2 10, Quaternion 0 $ V3 0 1 0)
    toolRef    <- newMVar (P $ V3 0 0  0, Quaternion 1 $ V3 0 0 0)
    return Graphics{..}
 

visualize :: (MonadError String m, MonadIO m, SeverityLog m)
          => FilePath
          -> Bool
          -> LogChannel
          -> Chan Request
          -> Chan Response
          -> m ()
visualize configurationFile debug logChannel requestChannel _responseChannel =
  do

    graphics <- guardIO initialize

    logInfo $ "Reading configuration from " ++ show configurationFile ++ " . . ."
    viewer <-
      join
        $ liftEither
        . either (Left . show) Right
        <$> guardIO (decodeFileEither configurationFile)


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
        display (logIO logChannel) debug viewer graphics
        return True


apply :: (MonadError String m, MonadIO m, SeverityLog m)
      => Graphics
      -> Chan Request
      -> m ()
apply Graphics{..} requestChannel =
  let
    conditionally f g x = if f x then g x else id
    onlyJust v = maybe (return ()) (void . swapMVar v)
    loop =
      do
        request <- readChan requestChannel
        void $ takeMVar lockRef
        manager <- readMVar managerRef
        void
          . swapMVar managerRef
          . delete                             (request ^. P.delete   )
          . insert                             (request ^. P.upsert   )
          . conditionally id     (const reset) (request ^. P.reset    )
          . conditionally (/= 0) set           (request ^. P.frameShow)
          $ manager
        putMVar lockRef ()
        onlyJust povRef  $ request ^. viewSet
        onlyJust toolRef $ request ^. toolSet
        loop
  in
    guardIO loop


display :: LoggerIO
        -> Bool
        -> Viewer Double
        -> Graphics
        -> IO ()
display logger debug viewer Graphics{..} =
  do

    logger Debug "Initializing OpenGL . . ."
    dlp <-
      setup
        (if debug then Just (logger Debug . show) else Nothing)
        "InfoVis Parallel"
        "InfoVis Parallel"
        (viewer :: Viewer Double)

    logger Debug "Creating array buffer manager . . ."
    createManager
      >>= prepare
      >>= putMVar managerRef
    lockRef `putMVar` ()

    logger Debug "Setting up display . . ."
    dlpViewerDisplay dlp viewer (readMVar povRef)
      $ readMVar managerRef >>= draw

    idleCallback $=! Just (idle Graphics{..})

#ifdef INFOVIS_SWAP_GROUP
    logger Debug "Joining swap group . . ."
    void
      $  maybe (return False) joinSwapGroup useSwapGroup
#endif

    logger Debug "Starting main loop . . ."
    mainLoop


idle :: Graphics
     -> IdleCallback
idle Graphics{..} =
  do
    void
      $ tryPutMVar startRef ()
    lock <- tryTakeMVar lockRef
    when (isJust lock)
      $ do
        void
          $   readMVar managerRef
          >>= prepare
          >>= swapMVar managerRef
        lockRef `putMVar` ()
    postRedisplay Nothing
