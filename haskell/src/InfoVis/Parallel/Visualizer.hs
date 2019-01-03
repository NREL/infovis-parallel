{-# LANGUAGE CPP              #-}
{-# LANGUAGE FlexibleContexts #-}


module InfoVis.Parallel.Visualizer (
  visualizeBuffers
) where


import Control.Lens.Getter ((^.))
import Control.Monad (join)
import Control.Monad.Except (MonadError, MonadIO, liftEither)
import Control.Monad.Log (Severity(..), logInfo)
import Data.IORef (IORef, newIORef, readIORef)
import Data.ProtocolBuffers (decodeMessage)
import Data.Serialize (runGet)
import Data.Yaml (decodeFileEither)
import Graphics.OpenGL.Util.Setup (dlpViewerDisplay, setup)
import Graphics.OpenGL.Util.Types (Viewer(..))
import Graphics.Rendering.OpenGL (($=!), ($~!))
import Graphics.UI.GLUT (mainLoop)
import Graphics.UI.GLUT.Callbacks.Global (IdleCallback, idleCallback)
import Graphics.UI.GLUT.Window (postRedisplay)
import InfoVis (SeverityLog, guardIO, withLogger)
import InfoVis.Parallel.ProtoBuf (upsert)
import InfoVis.Parallel.Rendering.Frames (createManager, draw, insert, prepare)
import Linear.Affine (Point(..))
import Linear.Quaternion (Quaternion(..))
import Linear.V3 (V3(..))

import qualified Data.ByteString as BS (readFile)

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

    withLogger
      $ \logger ->
        do

          logger Debug "Initializing OpenGL . . ."
          dlp <-
            setup
              (if debug then Just (logger Debug . show) else Nothing)
              "InfoVis Parallel"
              "InfoVis Parallel"
              (viewer :: Viewer Double)
      
          logger Debug "Creating array buffer manager . . ."
          manager <-
            (>>= prepare)
              $ flip (foldl insert) ((^. upsert) <$> buffers)
              <$> createManager
      
          angle <- newIORef 0
          let
            eye =
              do
                angle' <- readIORef angle
                return
                  (
                    P $ V3 (3 * sin angle') (2 + cos angle') 10
                  , Quaternion 0 $ V3 0 1 0
                  )
      
          logger Debug "Setting up display . . ."
          dlpViewerDisplay dlp viewer eye
            $ draw manager
      
          idleCallback $=! Just (idle angle)

#ifdef INFOVIS_SWAP_GROUP
          _ <- maybe (return False) joinSwapGroup useSwapGroup
#endif

          logger Debug "Starting main loop . . ."
          mainLoop


idle :: IORef Double -> IdleCallback
idle angle =
  do
    angle $~! (+ 0.01)
    postRedisplay Nothing
