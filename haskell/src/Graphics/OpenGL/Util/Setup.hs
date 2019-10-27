{-# LANGUAGE RecordWildCards    #-}


module Graphics.OpenGL.Util.Setup (
  Stereo(..)
, setup
, dlpViewerDisplay
, idle
) where


import Control.Monad (when, void)
import Data.Default (Default(def))
import Data.Maybe (isJust)
import Graphics.OpenGL.Util.Projection (OffAxisProjection(..), projection)
import Graphics.OpenGL.Util.Types (Display(..), PointOfView, Stereo(..), Viewer(..))
import Graphics.Rendering.DLP (DlpEncoding, DlpEye(..))
import Graphics.Rendering.DLP.Callbacks (DlpDisplay(..), dlpDisplayCallback)
import Graphics.Rendering.OpenGL (($=!))
import Graphics.Rendering.OpenGL.GL.CoordTrans (MatrixComponent, MatrixMode(..), Position(..), loadIdentity, matrixMode, viewport)
import Graphics.Rendering.OpenGL.GL.DebugOutput (DebugMessage, debugMessageCallback, debugOutput)
import Graphics.Rendering.OpenGL.GL.PerFragment (BlendingFactor(..), ComparisonFunction(..), alphaFunc, blend, blendFunc, depthFunc)
import Graphics.Rendering.OpenGL.GL.VertexArrays (Capability(Enabled))
import Graphics.UI.GLUT.Callbacks.Global (IdleCallback)
import Graphics.UI.GLUT.Callbacks.Window (DisplayCallback, reshapeCallback)
import Graphics.UI.GLUT.Initialization (ContextFlag(ForwardCompatibleContext), DisplayMode(..), initialDisplayMode, initialContextFlags, initialize)
import Graphics.UI.GLUT.Window (createWindow, fullScreen, postRedisplay)
import Linear.Affine (Point(..), (.+^))
import Linear.Conjugate (Conjugate)
import Linear.Epsilon (Epsilon)
import Linear.Vector ((*^))

import qualified Graphics.Rendering.DLP as D (DlpEncoding(..))
import qualified Linear.Quaternion as Q (rotate)


setup :: Maybe (DebugMessage -> IO ())
      -> String
      -> String
      -> Viewer a
      -> IO DlpEncoding
setup debug title program Viewer{..} =
  do
    let
      Display{..} = display
      dlp = case stereo of
        DLP        -> D.FrameSequential
        QuadBuffer -> D.QuadBuffer
        Cardboard  -> D.SideBySide
        Mono       -> D.LeftOnly
    void
      . initialize program
      . maybe id ( const ("-gldebug" :)) debug
      . maybe id ((("-display"  :) .) .(:)) identifier
      $ case geometry of
          Nothing           -> []
          Just "fullscreen" -> []
          Just geometry'    -> ["-geometry", geometry']
    initialContextFlags $=! [ForwardCompatibleContext]
    initialDisplayMode $=!
      (if stereo == QuadBuffer then (Stereoscopic :) else id)
        [WithDepthBuffer, DoubleBuffered]
    void $ createWindow title
    when (geometry == Just "fullscreen")
      fullScreen
    depthFunc $=! Just Less 
    blend     $=! Enabled
    blendFunc $=! (SrcAlpha, OneMinusSrcAlpha)
    alphaFunc $=! Just (Greater, 0)
    when (isJust debug)
      $ do
        debugOutput $=! Enabled
        debugMessageCallback $=! debug
    return dlp


dlpViewerDisplay :: (Conjugate a, Epsilon a, Fractional a, MatrixComponent a, Real a, RealFloat a, Show a)
                 => DlpEncoding
                 -> Viewer a
                 -> IO (PointOfView a)
                 -> DisplayCallback
                 -> IO ()
dlpViewerDisplay dlp Viewer{..} pov displayAction =
  do
    let
      Display{..} = display
    reshapeCallback $=! Just
      (\wh -> 
         do
           (P eyePosition, _) <- pov
           viewport $=! (Position 0 0, wh)
           matrixMode $=! Projection
           loadIdentity
           projection KooimaOffAxis screen (realToFrac <$> P eyePosition) nearPlane farPlane
           matrixMode $=! Modelview 0
           postRedisplay Nothing
      )
    dlpDisplayCallback $=!
      def
      {
        dlpEncoding = dlp
      , doDisplay =
          \eye ->
            do
              (eyePosition, eyeOrientation) <- pov
              let
                offset =
                  case eye of
                    LeftDlp  -> -0.5
                    RightDlp ->  0.5
                eyePosition' = eyePosition .+^ eyeOrientation `Q.rotate` (offset *^ eyeSeparation)
              matrixMode $=! Projection
              loadIdentity
              projection VTKOffAxis screen (realToFrac <$> eyePosition') nearPlane farPlane
              matrixMode $=! Modelview 0
              loadIdentity
              displayAction
      }


-- | An idle callback that simply posts a request for redisplay.
idle :: IdleCallback
idle = postRedisplay Nothing
