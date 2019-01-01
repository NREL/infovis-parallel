{-# LANGUAGE DeriveAnyClass   #-}
{-# LANGUAGE DeriveGeneric    #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RecordWildCards  #-}


module InfoVis.Parallel.Visualizer (
  visualizeBuffers
) where


import Control.Lens.Getter ((^.))
import Control.Monad (join, when)
import Control.Monad.Except (MonadError, MonadIO, liftEither)
import Data.Aeson.Types (FromJSON, ToJSON)
import Data.Default (def)
import Data.IORef (IORef, newIORef)
import Data.ProtocolBuffers (decodeMessage)
import Data.Serialize (runGet)
import Data.Yaml (decodeFileEither)
import GHC.Generics (Generic)
import Graphics.GL.Types (GLfloat)
import Graphics.Rendering.DLP (DlpEncoding(..))
import Graphics.Rendering.DLP.Callbacks (DlpDisplay(..), dlpDisplayCallback)
import Graphics.Rendering.OpenGL.GL (($=!), ($~!), get)
import Graphics.Rendering.OpenGL.GL.DebugOutput (debugMessageCallback, debugOutput)
import Graphics.Rendering.OpenGL.GL.PerFragment(ComparisonFunction(Less))
import Graphics.Rendering.OpenGL.GL.VertexArrays (Capability(..))
import Graphics.UI.GLUT (DisplayMode(..), IdleCallback, createWindow, depthFunc, fullScreen, getArgsAndInitialize, idleCallback, initialDisplayMode, mainLoop, postRedisplay)
import InfoVis (SeverityLog, guardIO)
import InfoVis.Parallel.NewTypes (DeltaGeometry, Displacement, Position)
import InfoVis.Parallel.ProtoBuf (upsert)
import InfoVis.Parallel.Rendering.Frames (createManager, draw, insert, prepare)
import Linear.Projection (lookAt, perspective)
import Linear.V3 (V3(..))

import qualified Data.ByteString as BS (readFile)


data Stereo =
    DLP        -- ^ Frame-sequential DLP 3D ReadySync stereo.
  | QuadBuffer -- ^ Quad buffer stereo.
  | Cardboard  -- ^ Google Cardboard stereo.
  | Mono       -- ^ No stereo.
    deriving (Bounded, Enum, Eq, FromJSON, Generic, Ord, Read, Show, ToJSON)


data Configuration =
  Configuration
  {
    stereo        :: Stereo
  , nearPlane     :: Double
  , farPlane      :: Double
  , eyeSeparation :: Displacement
  , host          :: Maybe String
  , port          :: Maybe Int
  , identifier    :: Maybe String
  , geometry      :: Maybe String
  , lowerLeft     :: Position
  , lowerRight    :: Position
  , upperLeft     :: Position
  }
    deriving (Eq, FromJSON, Generic, Ord, Read, Show, ToJSON)



visualizeBuffers :: (MonadError String m, MonadIO m, SeverityLog m)
                 => FilePath
                 -> Bool
                 -> [FilePath]
                 -> m ()
visualizeBuffers configurationFile debug bufferFiles =
  do

    Configuration{..} <-
      join
        $ liftEither
        . either (Left . show) Right
        <$> guardIO (decodeFileEither configurationFile)

    buffers <-
      (mapM liftEither =<<)
        . guardIO
        $ mapM (fmap (runGet decodeMessage) . BS.readFile)
          bufferFiles

    when debug
      $ do
          debugOutput          $=! Enabled
          debugMessageCallback $=! Just print -- FIXME: Use `logDebug`.
    
    _ <- getArgsAndInitialize
    initialDisplayMode $=! [WithDepthBuffer, DoubleBuffered]
    _ <- createWindow "DLP Stereo OpenGL Example"
    depthFunc $=! Just Less 
    fullScreen

    manager <-
      guardIO
        . (>>= prepare)
        $ flip (foldl insert) ((^. upsert) <$> buffers :: [[DeltaGeometry]])
        <$> createManager
 
    angle <- guardIO $ newIORef 0
    let
      testDraw =
        do
        angle' <- get angle
        let
          projection = perspective (pi / 3) 1 0.1 10
          modelView = lookAt (V3 (1 + sin angle') (2 + cos angle') (5 :: GLfloat)) (V3 0 0 0) (V3 0 1 0)
        draw projection modelView manager

    dlpDisplayCallback $=! def {dlpEncoding = LeftOnly, doDisplay = const testDraw}
    idleCallback $=! Just (idle angle)
    mainLoop


idle :: IORef GLfloat -> IdleCallback
idle angle =
  do
    angle $~! (+ 0.01)
    postRedisplay Nothing
