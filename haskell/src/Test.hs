module Main (
  main
) where


import Control.Monad (when)
import Data.Default (def)
import Data.IORef (IORef, newIORef)
import Control.Lens.Getter ((^.))
import Data.ProtocolBuffers (decodeMessage)
import Data.Serialize (runGet)
import Graphics.GL.Types (GLfloat)
import Graphics.Rendering.DLP (DlpEncoding(..))
import Graphics.Rendering.DLP.Callbacks (DlpDisplay(..), dlpDisplayCallback)
import Graphics.Rendering.OpenGL.GL (($=!), ($~!), get)
import Graphics.Rendering.OpenGL.GL.DebugOutput (debugMessageCallback, debugOutput)
import Graphics.Rendering.OpenGL.GL.PerFragment(ComparisonFunction(Less))
import Graphics.Rendering.OpenGL.GL.VertexArrays (Capability(..))
import Graphics.UI.GLUT (DisplayMode(..), IdleCallback, createWindow, depthFunc, fullScreen, getArgsAndInitialize, idleCallback, initialDisplayMode, mainLoop, postRedisplay)
import InfoVis.Parallel.ProtoBuf (Request, upsert)
import InfoVis.Parallel.NewTypes (DeltaGeometry(..), Glyph(..), Shape(..))
import InfoVis.Parallel.Rendering.Frames (addFrame, createManager, draw, insert, prepare, set)
import Linear.Affine (Point(..))
import Linear.Projection (lookAt, perspective)
import Linear.V3 (V3(..))

import qualified Data.ByteString as BS (readFile)


example :: [DeltaGeometry]
example =
  [
    DeltaGeometry 0 1 (Just $ Points Cube   [ [ P (V3 (-1.0) (-1.0) (-1.0))] ]) (Just 0.15) (Just 0x80808080) (Just "") Nothing
  , DeltaGeometry 0 2 (Just $ Points Cube   [ [ P (V3 (-1.0) (-1.0)   1.0 )] ]) (Just 0.20) (Just 0xA0808080) (Just "") Nothing
  , DeltaGeometry 0 3 (Just $ Points Cube   [ [ P (V3 (-1.0)   1.0  (-1.0))] ]) (Just 0.25) (Just 0x80A08080) (Just "") Nothing
  , DeltaGeometry 0 4 (Just $ Points Sphere [ [ P (V3 (-1.0)   1.0    1.0 )] ]) (Just 0.30) (Just 0x8080A080) (Just "") Nothing
  , DeltaGeometry 0 5 (Just $ Points Cube   [ [ P (V3   1.0  (-1.0) (-1.0))] ]) (Just 0.35) (Just 0xA0A0A0A0) (Just "") Nothing
  , DeltaGeometry 0 6 (Just $ Points Cube   [ [ P (V3   1.0  (-1.0)   1.0 )] ]) (Just 0.40) (Just 0x80A0A0A0) (Just "") Nothing
  , DeltaGeometry 0 7 (Just $ Points Cube   [ [ P (V3   1.0    1.0  (-1.0))] ]) (Just 0.45) (Just 0xA080A0A0) (Just "") Nothing
  , DeltaGeometry 0 8 (Just $ Points Cube   [ [ P (V3   1.0    1.0    1.0 )] ]) (Just 0.50) (Just 0xA0A080A0) (Just "") Nothing
  , DeltaGeometry 0 9 (Just $ Polylines     [
                                   [
                                     P (V3 (-1.0) (-1.0) (-1.0))
                                   , P (V3   1.0    1.0    1.0 )
                                   ]
                                 ]) (Just 0.05) (Just 0XA0A0A0FF) (Just "") Nothing
  , DeltaGeometry 0 10 (Just $ Rectangles    [
                                   (
                                     P (V3 (-1.0) (-1.0) (-1.0))
                                   , P (V3   1.0  (-1.0) (-1.0))
                                   , P (V3 (-1.0) (-1.0)   1.0 )
                                   )
                                 ]) (Just 0.01) (Just 0xFF0000FF) (Just "") Nothing
  , DeltaGeometry 0 11 (Just $ Axis            (
                                     P (V3   1.0  (-1.0) (-1.0))
                                   , P (V3 (-1.0)   1.0    1.0 )
                                   )
                                  ) (Just 0.05) (Just 0X00A000FF) (Just "") Nothing
  , DeltaGeometry 0 12 (Just $ Label           (
                                     P (V3 (-1.0) (-1.0) (-1.0))
                                   , P (V3   1.0    1.0    1.0 )
                                   , P (V3 (-2.0)   0.0  (-2.0))
                                   )
                                  ) (Just 0.10) (Just 0X0000FFFF) (Just "Testjwg") Nothing
  , DeltaGeometry 0 13 (Just $ Label           (
                                     P (V3 (-1.0) (-1.0)   1.0 )
                                   , P (V3   1.0  (-1.0)   1.0 )
                                   , P (V3 (-1.0) (-0.9)   1.0 )
                                   )
                                  ) (Just 0.10) (Just 0X00FF00FF) (Just "jTjgG") Nothing
  ]


testSetup :: [DeltaGeometry] -> IORef GLfloat -> IO (IO ())
testSetup deltaGeometries angle =
  do

    debugOutput $=! Enabled
    debugMessageCallback $=! Just print

    manager' <- createManager >>= addFrame 1 >>= addFrame 2 >>= addFrame 3
    let
      manager'' = insert manager' $ if True then deltaGeometries else example
    manager <- set 1 <$> prepare manager''

    return
      $ do
        angle' <- get angle
        let
          projection = perspective (pi / 3) 1 0.1 10
          modelView = lookAt (V3 (1 + sin angle') (2 + cos angle') (5 :: GLfloat)) (V3 0 0 0) (V3 0 1 0)
        draw projection modelView manager


-- | The main action.
main :: IO ()
main =
  do
    putStrLn "DLP Stereo OpenGL Example:"
    putStrLn "    Use the --fullscreen flag to run in full screen mode."
    putStrLn "    Use the --mono flag to run in monoscopic mode."
    putStrLn "    Use the --cardboard flag to run in side-by-side (Google Cardboard) mode."
    putStrLn "    Use the --quadbuffer flag to run in quad buffer stereo mode."
    (_, arguments) <- getArgsAndInitialize
    print arguments
    Right buffer <- fmap (runGet decodeMessage) . BS.readFile $ arguments !! 2 :: IO (Either String Request)
    print $ buffer ^. upsert
--  buffers <- runGetLazy decodeMessage <$> mapM BS.readFile $ drop 2 arguments
    initialDisplayMode $=! (if "--quadbuffer" `elem` arguments then (Stereoscopic :) else id) [WithDepthBuffer, DoubleBuffered]
    _ <- createWindow "DLP Stereo OpenGL Example"
    depthFunc $=! Just Less 
    when ("--fullscreen" `elem` arguments) fullScreen
    let encoding
          | "--quadbuffer" `elem` arguments = QuadBuffer
          | "--mono"       `elem` arguments = LeftOnly
          | "--cardboard"  `elem` arguments = SideBySide
          | otherwise                       = FrameSequential
    angle <- newIORef 0
    testDraw <- testSetup (buffer ^. upsert) angle
    dlpDisplayCallback $=! def {dlpEncoding = encoding, doDisplay = const testDraw}
    idleCallback $=! Just (idle angle)
    mainLoop

idle :: IORef GLfloat -> IdleCallback
idle angle =
  do
    angle $~! (+ 0.02)
    postRedisplay Nothing
