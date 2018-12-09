module Main (
  main
) where


import Control.Monad (when)
import Data.Default (def)
import Data.IORef (IORef, newIORef)
import Graphics.GL.Types (GLfloat, GLuint)
import Graphics.Rendering.DLP (DlpEncoding(..))
import Graphics.Rendering.DLP.Callbacks (DlpDisplay(..), dlpDisplayCallback)
import Graphics.Rendering.OpenGL.GL (($=!), ($~!), get)
import Graphics.Rendering.OpenGL.GL.DebugOutput (debugMessageCallback, debugOutput)
import Graphics.Rendering.OpenGL.GL.PerFragment(ComparisonFunction(Less))
import Graphics.Rendering.OpenGL.GL.Tensor (Vector3(..), Vector4(..), Vertex3(..))
import Graphics.Rendering.OpenGL.GL.VertexArrays (Capability(..))
import Graphics.UI.GLUT (DisplayMode(..), IdleCallback, createWindow, depthFunc, fullScreen, getArgsAndInitialize, idleCallback, initialDisplayMode, mainLoop, postRedisplay)
import InfoVis.Parallel.Rendering.Buffers (drawInstances, makeShapeBuffer, updateInstances)
import InfoVis.Parallel.Rendering.NewShapes (cube)
import InfoVis.Parallel.Rendering.Program
import Linear.Projection (lookAt, perspective)
import Linear.V3 (V3(..))


examplePositions :: [Vertex3 GLfloat]
examplePositions =
  [
    Vertex3 (-1) (-1) (-1)
  , Vertex3 (-1) (-1)   1
  , Vertex3 (-1)   1  (-1)
  , Vertex3 (-1)   1    1
  , Vertex3   1  (-1) (-1)
  , Vertex3   1  (-1)   1
  , Vertex3   1    1  (-1)
  , Vertex3   1    1    1
  ]


exampleRotations :: [Vector4 GLfloat]
exampleRotations =
  [
    Vector4 0 0 0 1
  , Vector4 s 0 0 s
  , Vector4 0 s 0 s
  , Vector4 0 0 s s
  , Vector4 m 0 0 s
  , Vector4 0 m 0 s
  , Vector4 0 0 m s
  , Vector4 0 n 0 0
  ]
    where
      s = 1 / sqrt 2
      m = - s
      n = - 1


exampleScales :: [Vector3 GLfloat]
exampleScales = 
  [
    Vector3 0.15 0.15 0.15
  , Vector3 0.20 0.20 0.20
  , Vector3 0.25 0.25 0.25
  , Vector3 0.30 0.30 0.30
  , Vector3 0.35 0.35 0.35
  , Vector3 0.40 0.40 0.40
  , Vector3 0.45 0.45 0.45
  , Vector3 0.50 0.50 0.50
  ]


exampleColors :: [GLuint]
exampleColors =
  [
    0x80808080
  , 0xA0808080
  , 0x80A08080
  , 0x8080A080
  , 0xA0A0A0A0
  , 0x80A0A0A0
  , 0xA080A0A0
  , 0xA0A080A0
  ]


testSetup :: IORef GLfloat -> IO (IO ())
testSetup angle =
  do

    debugOutput $=! Enabled
    debugMessageCallback $=! Just print

    shapeProgram <- prepareShapeProgram

    shapeBuffer <-
      makeShapeBuffer shapeProgram (cube 1)
        >>= updateInstances
                (Just examplePositions)
                (Just exampleRotations)
                (Just exampleScales   )
                (Just exampleColors   )

    return
      $ do
        angle' <- get angle
        let
          projection = perspective (pi / 3) 1 0.1 10
          modelView = lookAt (V3 (-5 :: GLfloat) (1 +sin angle') (2 + cos angle')) (V3 0 0 0) (V3 0 1 0)
        drawInstances shapeBuffer projection modelView


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
