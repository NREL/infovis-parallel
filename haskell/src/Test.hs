module Main (
  main
) where


import Control.Monad (when)
import Data.Default (def)
import Data.IORef (IORef, newIORef)
import Graphics.GL.Types (GLfloat)
import Graphics.Rendering.DLP (DlpEncoding(..))
import Graphics.Rendering.DLP.Callbacks (DlpDisplay(..), dlpDisplayCallback)
import Graphics.Rendering.OpenGL.GL (($=!), ($~!), get)
import Graphics.Rendering.OpenGL.GL.DebugOutput (debugMessageCallback, debugOutput)
import Graphics.Rendering.OpenGL.GL.PerFragment(ComparisonFunction(Less))
import Graphics.Rendering.OpenGL.GL.VertexArrays (Capability(..))
import Graphics.UI.GLUT (DisplayMode(..), IdleCallback, createWindow, depthFunc, fullScreen, getArgsAndInitialize, idleCallback, initialDisplayMode, mainLoop, postRedisplay)
import InfoVis.Parallel.NewTypes (Geometry(..), Glyph(..), Identifier, Shape(..))
import InfoVis.Parallel.Rendering.Frames (addFrame, createManager, draw, insert, prepare)
import Linear.Affine (Point(..))
import Linear.Projection (lookAt, perspective)
import Linear.V3 (V3(..))


example :: [(Identifier, Geometry)]
example =
  [
    ( 1, Geometry (Points Cube   [ [ P (V3 (-1.0) (-1.0) (-1.0))] ]) 0.15 0x80808080 "")
  , ( 2, Geometry (Points Cube   [ [ P (V3 (-1.0) (-1.0)   1.0 )] ]) 0.20 0xA0808080 "")
  , ( 3, Geometry (Points Cube   [ [ P (V3 (-1.0)   1.0  (-1.0))] ]) 0.25 0x80A08080 "")
  , ( 4, Geometry (Points Sphere [ [ P (V3 (-1.0)   1.0    1.0 )] ]) 0.30 0x8080A080 "")
  , ( 5, Geometry (Points Cube   [ [ P (V3   1.0  (-1.0) (-1.0))] ]) 0.35 0xA0A0A0A0 "")
  , ( 6, Geometry (Points Cube   [ [ P (V3   1.0  (-1.0)   1.0 )] ]) 0.40 0x80A0A0A0 "")
  , ( 7, Geometry (Points Cube   [ [ P (V3   1.0    1.0  (-1.0))] ]) 0.45 0xA080A0A0 "")
  , ( 8, Geometry (Points Cube   [ [ P (V3   1.0    1.0    1.0 )] ]) 0.50 0xA0A080A0 "")
  , ( 9, Geometry (Polylines     [
                                   [
                                     P (V3 (-1.0) (-1.0) (-1.0))
                                   , P (V3   1.0    1.0    1.0 )
                                   ]
                                 ]) 0.05 0XA0A0A0FF "")
  , (10, Geometry (Rectangles    [
                                   (
                                     P (V3 (-1.0) (-1.0) (-1.0))
                                   , P (V3   1.0  (-1.0) (-1.0))
                                   , P (V3 (-1.0) (-1.0)   1.0 )
                                   )
                                 ]) 0.01 0xFF0000FF "")
  , (11, Geometry (Axis            (
                                     P (V3   1.0  (-1.0) (-1.0))
                                   , P (V3 (-1.0)   1.0    1.0 )
                                   )
                                  ) 0.05 0X00A000FF "")
  , (12, Geometry (Label           (
                                     P (V3 (-1.0) (-1.0) (-1.0))
                                   , P (V3   1.0    1.0    1.0 )
                                   , P (V3 (-2.0)   0.0  (-2.0))
                                   )
                                  ) 0.10 0X0000FFFF "Testjwg")
  , (13, Geometry (Label           (
                                     P (V3 (-1.0) (-1.0)   1.0 )
                                   , P (V3   1.0  (-1.0)   1.0 )
                                   , P (V3 (-1.0) (-0.9)   1.0 )
                                   )
                                  ) 0.10 0X00FF00FF "jTjgG")
  ]


testSetup :: IORef GLfloat -> IO (IO ())
testSetup angle =
  do

    debugOutput $=! Enabled
    debugMessageCallback $=! Just print

    manager' <- createManager >>= addFrame 0
    let
      manager'' = insert manager' 0 example
    manager <- prepare 0 manager''

    return
      $ do
        angle' <- get angle
        let
          projection = perspective (pi / 3) 1 0.1 10
          modelView = lookAt (V3 (1 + sin angle') (2 + cos angle') (5 :: GLfloat)) (V3 0 0 0) (V3 0 1 0)
        draw 0 projection modelView manager


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
    testDraw <- testSetup angle
    dlpDisplayCallback $=! def {dlpEncoding = encoding, doDisplay = const testDraw}
    idleCallback $=! Just (idle angle)
    mainLoop

idle :: IORef GLfloat -> IdleCallback
idle angle =
  do
    angle $~! (+ 0.02)
    postRedisplay Nothing
