{-|
Module      :  Main
Copyright   :  (c) 2015 Brian W Bush
License     :  MIT
Maintainer  :  Brian W Bush <consult@brianwbush.info>
Stability   :  Stable
Portability :  Portable

Example application illustrating frame-sequential DLP.
-}


module Main (
-- * Entry Point
  main
) where


import Control.Monad (when)
import Data.Default (def)
import Data.IORef (IORef, newIORef)
import Graphics.Rendering.DLP (DlpEncoding(..), DlpEye(..))
import Graphics.Rendering.DLP.Callbacks (DlpDisplay(..), DlpDisplayCallback, dlpDisplayCallback)
import Graphics.Rendering.OpenGL.GL (Color3(..), ComparisonFunction(Less), PrimitiveMode(..), Vector3(..), Vertex3(..), Vector4(..), GLdouble, GLfloat, GLuint, ($=!), ($~!), color, get, loadIdentity, preservingMatrix, renderPrimitive, rotate, translate, vertex)
import Graphics.UI.GLUT (DisplayMode(..), IdleCallback, createWindow, depthFunc, fullScreen, getArgsAndInitialize, idleCallback, initialDisplayMode, mainLoop, postRedisplay)


import Data.Array.Storable (newListArray, withStorableArray)
import Foreign.Ptr (nullPtr, plusPtr)
import Foreign.Storable (Storable, poke, sizeOf)
import Graphics.Rendering.OpenGL.GL (($=), deleteObjectName, genObjectName)
import Graphics.Rendering.OpenGL.GL (GLfloat)
import Graphics.Rendering.OpenGL.GL.BufferObjects (BufferAccess(..), BufferObject, BufferTarget(..), BufferUsage(DynamicDraw), TransferDirection(WriteToBuffer), bindBuffer, bufferData, bufferSubData, withMappedBuffer)
import Graphics.Rendering.OpenGL.GL.DebugOutput (debugMessageCallback, debugOutput)
import Graphics.Rendering.OpenGL.GL.Shaders.Attribs (attribLocation)
import Graphics.Rendering.OpenGL.GL.Shaders.ProgramObjects (attachShader, createProgram, currentProgram, linkProgram, programSeparable)
import Graphics.Rendering.OpenGL.GL.Shaders.ShaderObjects (ShaderType(FragmentShader, VertexShader), compileShader, createShader, shaderSourceBS)
import Graphics.Rendering.OpenGL.GL.Shaders.Uniform(uniform, uniformLocation)
import Graphics.Rendering.OpenGL.GL.VertexArrays (Capability(..), ClientArrayType(..), DataType(Float, UnsignedInt), NumArrayIndices, VertexArrayDescriptor(..), arrayPointer, clientState, drawArraysInstanced, vertexAttribArray, vertexAttribPointer)
import Graphics.Rendering.OpenGL.GL.VertexSpec (AttribLocation(..), IntegerHandling(KeepIntegral, ToFloat))
import Graphics.Rendering.OpenGL.GL.CoordTrans(GLmatrix, MatrixOrder(RowMajor), newMatrix)
import Linear.Matrix((!*!))
import Linear.Projection (lookAt, perspective)
import Linear.V3 (V3(..))
import Linear.V4 (V4(..))

import Graphics.GL.ARB.InstancedArrays (glVertexAttribDivisorARB)

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


cubeQuads :: [Vector3 GLfloat]
cubeQuads =
  [
    Vector3   0.5    0.5    0.5 , Vector3   0.5    0.5  (-0.5), Vector3   0.5  (-0.5) (-0.5), Vector3   0.5  (-0.5)   0.5
  , Vector3   0.5    0.5    0.5 , Vector3   0.5    0.5  (-0.5), Vector3 (-0.5)   0.5  (-0.5), Vector3 (-0.5)   0.5    0.5
  , Vector3   0.5    0.5    0.5 , Vector3   0.5  (-0.5)   0.5 , Vector3 (-0.5) (-0.5)   0.5 , Vector3 (-0.5)   0.5    0.5
  , Vector3 (-0.5)   0.5    0.5 , Vector3 (-0.5)   0.5  (-0.5), Vector3 (-0.5) (-0.5) (-0.5), Vector3 (-0.5) (-0.5)   0.5
  , Vector3   0.5  (-0.5)   0.5 , Vector3   0.5  (-0.5) (-0.5), Vector3 (-0.5) (-0.5) (-0.5), Vector3 (-0.5) (-0.5)   0.5
  , Vector3   0.5    0.5  (-0.5), Vector3   0.5  (-0.5) (-0.5), Vector3 (-0.5) (-0.5) (-0.5), Vector3 (-0.5)   0.5  (-0.5)
  ]


cubePositions :: [Vector3 GLfloat]
cubePositions =
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


cubeScales :: [GLfloat]
cubeScales = [0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40]


cubeRotations :: [Vector4 GLfloat]
cubeRotations =
  [
    Vector4 1 0 0 1
  , Vector4 1 0 0 1
  , Vector4 1 0 0 1
  , Vector4 1 0 0 1
  , Vector4 1 0 0 1
  , Vector4 1 0 0 1
  , Vector4 1 0 0 1
  , Vector4 1 0 0 1
  ]


cubeColors :: [GLuint]
cubeColors = [0x80808080, 0xA0808080, 0x80A08080, 0x8080A080, 0xA0A0A0A0, 0x80A0A0A0, 0xA080A0A0, 0xA0A080A0]


testSetup :: IO (IO ())
testSetup =
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
                vertexAttribArray l $=! Enabled
                bindBuffer ArrayBuffer $=! Just bufferObject
                vertexAttribPointer l $=! (g, VertexArrayDescriptor k t (fromIntegral m) nullPtr)
                glVertexAttribDivisorARB l' i
            , bufferObject
            )

    (quadsBinder    , _quadsBO    ) <- buildBuffer "mesh_position"     3 Float       ToFloat      0 cubeQuads
    (positionsBinder, _positionsBO) <- buildBuffer "instance_position" 3 Float       ToFloat      1 cubePositions
    (rotationsBinder, _rotationsBO) <- buildBuffer "instance_rotation" 4 Float       ToFloat      1 cubeRotations
    (scalesBinder   , _scalesBO   ) <- buildBuffer "instance_scale"    3 Float       ToFloat      1 cubeScales
    (colorsBinder   , _colorsBO   ) <- buildBuffer "instance_color"    1 UnsignedInt KeepIntegral 1 cubeColors

    return
      $ do
        putStrLn "DRAW"
        currentProgram $=! Just program
        let
          projection = perspective (pi / 3) 1 0.1 10
          modelView = lookAt (V3 (-5 :: GLfloat) 0 0) (V3 0 0 0) (V3 0 1 0)
          (V4 (V4 a00 a01 a02 a03) (V4 a10 a11 a12 a13) (V4 a20 a21 a22 a23) (V4 a30 a31 a32 a33)) = projection !*! modelView
        projectionModelView <- newMatrix RowMajor [a00, a01, a02, a03, a10, a11, a12, a13, a20, a21, a22, a23, a30, a31, a32, a33] :: IO (GLmatrix GLfloat)
        uniform projectionModelViewLoc $=! projectionModelView
        quadsBinder
        positionsBinder
        rotationsBinder
        scalesBinder
        colorsBinder
        drawArraysInstanced Quads 0 6 8

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
    angle <- newIORef 0
    let encoding
          | "--quadbuffer" `elem` arguments = QuadBuffer
          | "--mono"       `elem` arguments = LeftOnly
          | "--cardboard"  `elem` arguments = SideBySide
          | otherwise                       = FrameSequential
    testDraw <- testSetup
    dlpDisplayCallback $=! def {dlpEncoding = encoding, doDisplay = const testDraw}
--  dlpDisplayCallback $=! def {dlpEncoding = encoding, doDisplay = display angle}
--  idleCallback $=! Just (idle angle)
    mainLoop


-- | The idle callback.
idle :: IORef GLfloat -> IdleCallback
idle angle =
  do
    angle $~! (+ 0.1)
    postRedisplay Nothing


-- | Draw rotating cubes.
display :: IORef GLfloat -> DlpDisplayCallback
display angle eye =
  do
    angle' <- get angle
    let offset = case eye of
                   LeftDlp  ->  0.05 
                   RightDlp -> -0.05 :: GLfloat
    loadIdentity
    preservingMatrix $ do
      translate $ Vector3 offset 0 0.5
      rotate angle' $ Vector3 1 1 1
      color $ Color3 0.5 0.35 (0 :: GLfloat)
      cube 0.5
      color $ Color3 0.5 0.65 (1 :: GLfloat)
      cubeFrame 0.5
    preservingMatrix $ do
      translate $ Vector3 offset 0 0
      rotate (- angle') $ Vector3 1 1 1
      color $ Color3 0 0.35 (0.5 :: GLfloat)
      cube 0.25
      color $ Color3 1 0.65 (0.5 :: GLfloat)
      cubeFrame 0.25


-- | Make a cube.  *Source:* \<<https://wiki.haskell.org/OpenGLTutorial2>\>.
cube :: GLfloat -> IO ()
cube w =
  renderPrimitive Quads
    $ mapM_ vertex3f
    [
      ( w, w, w), ( w, w,-w), ( w,-w,-w), ( w,-w, w)
    , ( w, w, w), ( w, w,-w), (-w, w,-w), (-w, w, w)
    , ( w, w, w), ( w,-w, w), (-w,-w, w), (-w, w, w)
    , (-w, w, w), (-w, w,-w), (-w,-w,-w), (-w,-w, w)
    , ( w,-w, w), ( w,-w,-w), (-w,-w,-w), (-w,-w, w)
    , ( w, w,-w), ( w,-w,-w), (-w,-w,-w), (-w, w,-w)
    ]


-- | Make the frame of a cube.  *Source:* \<<https://wiki.haskell.org/OpenGLTutorial2>\>.
cubeFrame :: GLfloat -> IO ()
cubeFrame w =
  renderPrimitive Lines
    $ mapM_ vertex3f
    [
      ( w,-w, w), ( w, w, w)
    , ( w, w, w), (-w, w, w)
    , (-w, w, w), (-w,-w, w)
    , (-w,-w, w), ( w,-w, w)
    , ( w,-w, w), ( w,-w,-w)
    , ( w, w, w), ( w, w,-w)
    , (-w, w, w), (-w, w,-w)
    , (-w,-w, w), (-w,-w,-w)
    , ( w,-w,-w), ( w, w,-w)
    , ( w, w,-w), (-w, w,-w)
    , (-w, w,-w), (-w,-w,-w)
    , (-w,-w,-w), ( w,-w,-w)
    ]


-- | Make a vertex.
vertex3f :: (GLfloat, GLfloat, GLfloat) -> IO ()
vertex3f (x, y, z) = vertex $ Vertex3 x y z
