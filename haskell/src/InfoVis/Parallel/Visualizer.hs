{-# LANGUAGE CPP              #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RecordWildCards  #-}


module InfoVis.Parallel.Visualizer (
  visualizeBuffers
) where


import Control.Concurrent.MVar (MVar, newEmptyMVar, putMVar, readMVar, swapMVar, takeMVar, tryTakeMVar)
import Control.Lens.Getter ((^.))
import Control.Monad (join, void, when)
import Control.Monad.Except (MonadError, MonadIO, liftEither)
import Control.Monad.Log (Severity(..), logInfo)
import Data.IORef (IORef, newIORef, readIORef, writeIORef)
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
import InfoVis (LoggerIO, SeverityLog, guardIO, forkLoggedIO, forkLoggedOS, logIO, makeLogger)
import InfoVis.Parallel.NewTypes (PositionRotation)
import InfoVis.Parallel.ProtoBuf (upsert)
import InfoVis.Parallel.Rendering.Frames (Manager, createManager, draw, insert, prepare)
import Linear.Affine (Point(..))
import Linear.Quaternion (Quaternion(..))
import Linear.V3 (V3(..))

import qualified Data.ByteString as BS (readFile)

#ifdef INFOVIS_SWAP_GROUP
import Graphics.OpenGL.Functions (joinSwapGroup)
#endif


data Graphics =
  Graphics
  {
    managerRef :: MVar Manager
  , povRef     :: MVar PositionRotation
  , toolRef    :: MVar PositionRotation
  , lockRef    :: MVar ()
  }


visualizeBuffers :: (MonadError String m, MonadIO m, SeverityLog m)
                 => FilePath
                 -> Bool
                 -> [FilePath]
                 -> m ()
visualizeBuffers configurationFile debug bufferFiles =
  do

    logInfo $ "Reading configuration from " ++ show configurationFile ++ " . . ."
    viewer <-
      join
        $ liftEither
        . either (Left . show) Right
        <$> guardIO (decodeFileEither configurationFile)

    logInfo "Reading protocol buffers . . ."
    buffers <-
      (mapM liftEither =<<)
        . guardIO
        $ mapM (fmap (runGet decodeMessage) . BS.readFile)
          bufferFiles

    managerRef <- guardIO newEmptyMVar
    povRef     <- guardIO newEmptyMVar
    toolRef    <- guardIO newEmptyMVar
    lockRef    <- guardIO newEmptyMVar 

    (logChannel, logger) <- makeLogger

    void
      . forkLoggedIO logChannel
      . guardIO
      $ do
          void
            $ takeMVar lockRef
          manager <- readMVar managerRef
          void
            . swapMVar managerRef
            $ foldl insert manager ((^. upsert) <$> buffers)
          putMVar lockRef ()
          return False

    logInfo "Forking OpenGL . . ."
    void
      . forkLoggedOS logChannel
      . guardIO
      $ do
        display (logIO logChannel) debug viewer Graphics{..}
        return True

    logger


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

    angleRef <- newIORef 0
    povRef  `putMVar` (P $ V3 3 2 10 , Quaternion 0 $ V3 0 1 0)
    toolRef `putMVar` (P $ V3 0 0  0 , Quaternion 1 $ V3 0 0 0)
    lockRef `putMVar` ()
       
    logger Debug "Setting up display . . ."
    dlpViewerDisplay dlp viewer (readMVar povRef)
      $ readMVar managerRef >>= draw

    idleCallback $=! Just (idle angleRef Graphics{..})

#ifdef INFOVIS_SWAP_GROUP
    logger Debug "Joining swap group . . ."
    void
      $  maybe (return False) joinSwapGroup useSwapGroup
#endif

    logger Debug "Starting main loop . . ."
    mainLoop


idle :: IORef Double
     -> Graphics
     -> IdleCallback
idle angleRef Graphics{..} =
  do
    lock <- tryTakeMVar lockRef
    when (isJust lock)
      $ do
        void
          $   readMVar managerRef
          >>= prepare
          >>= swapMVar managerRef
        lockRef `putMVar` ()
    angle <- (0.02 +) <$> readIORef angleRef
    angleRef `writeIORef` angle
    void
      $ povRef  `swapMVar` (P $ V3 (3 + sin angle) (2 + cos angle) 10 , Quaternion 0 $ V3 0 1 0)
    postRedisplay Nothing
