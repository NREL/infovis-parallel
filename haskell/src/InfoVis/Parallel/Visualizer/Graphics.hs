{-# LANGUAGE CPP              #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RecordWildCards  #-}


module InfoVis.Parallel.Visualizer.Graphics (
  visualize
) where


import Control.Concurrent.Chan (Chan, readChan, writeChan)
import Control.Concurrent.MVar (MVar, newEmptyMVar, newMVar, putMVar, readMVar, swapMVar, takeMVar, tryPutMVar, tryTakeMVar)
import Control.Lens.Getter ((^.))
import Control.Lens.Setter ((.~))
import Control.Monad (forever, void, when)
import Control.Monad.Except (MonadError, MonadIO)
import Control.Monad.Log (Severity(..), logInfo)
import Data.Maybe (isJust)
import Graphics.OpenGL.Util.Setup (dlpViewerDisplay, setup)
import Graphics.OpenGL.Util.Types (Viewer)
import Graphics.Rendering.OpenGL (($=!))
import Graphics.UI.GLUT (mainLoop)
import Graphics.UI.GLUT.Callbacks.Global (IdleCallback, idleCallback)
import Graphics.UI.GLUT.Window (postRedisplay)
import InfoVis (LogChannel, LoggerIO, SeverityLog, guardIO, forkLoggedIO, forkLoggedOS, logIO)
import InfoVis.Parallel.NewTypes (PositionRotation)
import InfoVis.Parallel.ProtoBuf (Request)
import InfoVis.Parallel.Rendering.Buffers (ShapeBuffer)
import InfoVis.Parallel.Rendering.Frames (Manager, createManager, currentFrame, delete, draw, insert, prepare, program, reset)
import InfoVis.Parallel.Rendering.Selector (createSelector, drawSelector, prepareSelector)
import InfoVis.Parallel.Rendering.Text (drawText)
import Linear.Affine (Point(..))
import Linear.Quaternion (Quaternion(..))
import Linear.V3 (V3(..))
import Network.UI.Kafka.Types (Event)
import Network.UI.Kafka.GLUT (setCallbacks)

import qualified InfoVis.Parallel.ProtoBuf as P (delete, display, frameShow, reset, toolSet, upsert, viewSet)

#ifdef INFOVIS_SWAP_GROUP
import Graphics.OpenGL.Functions (joinSwapGroup)
#endif


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
          -> Chan Event
          -> m ()
visualize viewer debug logChannel requestChannel responseChannel =
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
        display (logIO logChannel) debug viewer graphics responseChannel
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
        -> Chan Event
        -> IO ()
display logger debug viewer Graphics{..} responseChannel =
  do

    logger Debug "Initializing OpenGL . . ."
    dlp <-
      setup 
        (if debug then Just (logger Debug . show) else Nothing)
        "InfoVis Parallel"
        "InfoVis Parallel"
        viewer

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
    dlpViewerDisplay dlp viewer (readMVar povRef)
      $ do
        readMVar managerRef  >>= draw
        readMVar selectorRef >>= drawSelector
        readMVar textRef     >>= drawText

    setCallbacks [minBound..maxBound]
      $ writeChan responseChannel

    idleCallback $=! Just (idle Graphics{..} responseChannel)

#ifdef INFOVIS_SWAP_GROUP
    logger Debug "Joining swap group . . ."
    void
      $  maybe (return False) joinSwapGroup useSwapGroup
#endif

    logger Debug "Starting main loop . . ."
    mainLoop


idle :: Graphics
     -> Chan Event
     -> IdleCallback
idle Graphics{..} _responseChannel =
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
    postRedisplay Nothing
