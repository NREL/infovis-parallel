module Main (
  main
) where


import Control.Monad (when)
import Data.Array.Storable (newListArray, withStorableArray)
import Data.Default (def)
import Data.IORef (IORef, newIORef)
import Foreign.Ptr (nullPtr)
import Foreign.Storable (sizeOf)
import Graphics.GL.ARB.InstancedArrays (glVertexAttribDivisorARB)
import Graphics.GL.Types (GLfloat, GLuint)
import Graphics.Rendering.DLP (DlpEncoding(..))
import Graphics.Rendering.DLP.Callbacks (DlpDisplay(..), dlpDisplayCallback)
import Graphics.Rendering.OpenGL.GL (($=!), ($~!), genObjectName, get)
import Graphics.Rendering.OpenGL.GL.BufferObjects (BufferTarget(..), BufferUsage(DynamicDraw), bindBuffer, bufferData)
import Graphics.Rendering.OpenGL.GL.CoordTrans(GLmatrix, MatrixOrder(RowMajor), newMatrix)
import Graphics.Rendering.OpenGL.GL.DebugOutput (debugMessageCallback, debugOutput)
import Graphics.Rendering.OpenGL.GL.PerFragment(ComparisonFunction(Less))
import Graphics.Rendering.OpenGL.GL.Shaders.Attribs (attribLocation)
import Graphics.Rendering.OpenGL.GL.Shaders.ProgramObjects (attachShader, createProgram, currentProgram, linkProgram, programSeparable)
import Graphics.Rendering.OpenGL.GL.Shaders.ShaderObjects (ShaderType(VertexShader), compileShader, createShader, shaderSourceBS)
import Graphics.Rendering.OpenGL.GL.Shaders.Uniform(uniform, uniformLocation)
import Graphics.Rendering.OpenGL.GL.Tensor (Vector3(..), Vector4(..))
import Graphics.Rendering.OpenGL.GL.VertexArrays (Capability(..), DataType(Float, UnsignedInt), VertexArrayDescriptor(..), drawArraysInstanced, vertexAttribArray, vertexAttribPointer)
import Graphics.Rendering.OpenGL.GL.VertexSpec (AttribLocation(..), IntegerHandling(KeepIntegral, ToFloat))
import Graphics.UI.GLUT (DisplayMode(..), IdleCallback, createWindow, depthFunc, fullScreen, getArgsAndInitialize, idleCallback, initialDisplayMode, mainLoop, postRedisplay)
import InfoVis.Parallel.Rendering.NewShapes
import Linear.Matrix((!*!))
import Linear.Projection (lookAt, perspective)
import Linear.V3 (V3(..))
import Linear.V4 (V4(..))

import qualified Data.ByteString.Char8 as BS (ByteString, pack)


vertexShaderSource :: BS.ByteString
vertexShaderSource =
  BS.pack
    "#version 130                                                                                             \n\
    \                                                                                                         \n\
    \uniform mat4 projection_modelview;                                                                       \n\
    \                                                                                                         \n\
    \in vec3 mesh_position;                                                                                   \n\
    \                                                                                                         \n\
    \in vec3 instance_position;                                                                               \n\
    \in vec3 instance_scale   ;                                                                               \n\
    \in vec4 instance_rotation;                                                                               \n\
    \in uint instance_color   ;                                                                               \n\
    \                                                                                                         \n\
    \vec3 rotate(vec3 p, vec4 q) {                                                                            \n\
    \  return p + 2 * cross(q.xyz, cross(q.xyz, p) + q.w * p);                                                \n\
    \}                                                                                                        \n\
    \                                                                                                         \n\
    \void main() {                                                                                            \n\
    \  vec4 position = vec4(rotate(mesh_position * instance_scale, instance_rotation) + instance_position, 1);\n\
    \  vec4 color = vec4(float((0xFF000000u & instance_color) >> 24) / 255,                                   \n\
    \                    float((0x00FF0000u & instance_color) >> 16) / 255,                                   \n\
    \                    float((0x0000FF00u & instance_color) >>  8) / 255,                                   \n\
    \                    float( 0x000000FFu & instance_color       ) / 255);                                  \n\
    \  gl_Position = projection_modelview * position;                                                         \n\
    \  gl_FrontColor = color;                                                                                 \n\
    \}"


examplePositions :: [Vector3 GLfloat]
examplePositions =
  [
    Vector3 (-1) (-1) (-1)
  , Vector3 (-1) (-1)   1
  , Vector3 (-1)   1  (-1)
  , Vector3 (-1)   1    1
  , Vector3   1  (-1) (-1)
  , Vector3   1  (-1)   1
  , Vector3   1    1  (-1)
  , Vector3   1    1    1
  ]


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


exampleRotations :: [Vector4 GLfloat]
exampleRotations =
  [
    Vector4 0 0 0 1
  , Vector4 0 0 0 1
  , Vector4 0 0 0 1
  , Vector4 0 0 0 1
  , Vector4 0 0 0 1
  , Vector4 0 0 0 1
  , Vector4 0 0 0 1
  , Vector4 0 0 0 1
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

    program <- createProgram
    programSeparable program $=! True

    vertexShader <- createShader VertexShader
    shaderSourceBS vertexShader $=! vertexShaderSource
    compileShader vertexShader
    program `attachShader` vertexShader 

    linkProgram program

    projectionModelViewLoc <- get $ uniformLocation program "projection_modelview"

    let
      buildBuffer p k t g i xs =
        do
          let
            m = sizeOf $ head xs
            n = length xs
            size = n * m
          bufferObject <- genObjectName
          bindBuffer ArrayBuffer $=! Just bufferObject
          values <- newListArray (0, size) xs
          withStorableArray values $ \ptr -> bufferData ArrayBuffer $=! (toEnum size, ptr, DynamicDraw)
          bindBuffer ArrayBuffer $=! Nothing
          l@(AttribLocation l') <- get $ attribLocation program p
          return
            (
              do
                bindBuffer ArrayBuffer $=! Just bufferObject
                vertexAttribPointer l $=! (g, VertexArrayDescriptor k t (fromIntegral m) nullPtr)
                when i
                 $ glVertexAttribDivisorARB l' 1
                vertexAttribArray l $=! Enabled
            , bufferObject
            )
      (primitiveMode, primitives) = cube (1 :: GLfloat)

    (quadsBinder    , _quadsBO    ) <- buildBuffer "mesh_position"     3 Float       ToFloat      False primitives
    (positionsBinder, _positionsBO) <- buildBuffer "instance_position" 3 Float       ToFloat      True  examplePositions
    (rotationsBinder, _rotationsBO) <- buildBuffer "instance_rotation" 4 Float       ToFloat      True  exampleRotations
    (scalesBinder   , _scalesBO   ) <- buildBuffer "instance_scale"    3 Float       ToFloat      True  exampleScales
    (colorsBinder   , _colorsBO   ) <- buildBuffer "instance_color"    1 UnsignedInt KeepIntegral True  exampleColors

    return
      $ do
        currentProgram $=! Just program
        angle' <- get angle
        let
          projection = perspective (pi / 3) 1 0.1 10
          modelView = lookAt (V3 (-5 :: GLfloat) (1 +sin angle') (2 + cos angle')) (V3 0 0 0) (V3 0 1 0)
          (V4 (V4 a00 a01 a02 a03) (V4 a10 a11 a12 a13) (V4 a20 a21 a22 a23) (V4 a30 a31 a32 a33)) = projection !*! modelView
        projectionModelView <- newMatrix RowMajor [a00, a01, a02, a03, a10, a11, a12, a13, a20, a21, a22, a23, a30, a31, a32, a33] :: IO (GLmatrix GLfloat)
        uniform projectionModelViewLoc $=! projectionModelView
        quadsBinder
        positionsBinder
        rotationsBinder
        scalesBinder
        colorsBinder
        drawArraysInstanced
          primitiveMode
          0
          (fromIntegral $ length primitives)
          (fromIntegral $ length examplePositions)


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
