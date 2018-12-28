{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}


module InfoVis.Parallel.Rendering.Program (
  ShapeProgram
, prepareShapeProgram
, deleteShapeProgram
, selectShapeProgram
, setProjectionModelView
, setProjectionModelView'
, bindMesh
, bindPositions
, bindRotations
, bindScales
, bindColors
) where


import Control.Monad (when)
import Foreign.Ptr (nullPtr)
import Graphics.GL.ARB.InstancedArrays (glVertexAttribDivisorARB)
import Graphics.GL.Types (GLfloat, GLuint)
import Graphics.Rendering.OpenGL.GL (($=!), deleteObjectName, get)
import Graphics.Rendering.OpenGL.GL.BufferObjects (BufferObject, BufferTarget(..), bindBuffer)
import Graphics.Rendering.OpenGL.GL.CoordTrans(GLmatrix, Matrix, MatrixComponent, MatrixOrder(RowMajor), matrix, newMatrix)
import Graphics.Rendering.OpenGL.GL.Shaders.Attribs (attribLocation)
import Graphics.Rendering.OpenGL.GL.Shaders.ProgramObjects (Program, attachShader, createProgram, currentProgram, linkProgram, programSeparable)
import Graphics.Rendering.OpenGL.GL.Shaders.ShaderObjects (ShaderType(VertexShader), compileShader, createShader, shaderSourceBS)
import Graphics.Rendering.OpenGL.GL.Shaders.Uniform(UniformLocation, uniform, uniformLocation)
import Graphics.Rendering.OpenGL.GL.VertexArrays (Capability(..), DataType(Float, UnsignedInt), VertexArrayDescriptor(..), vertexAttribArray, vertexAttribPointer)
import Graphics.Rendering.OpenGL.GL.VertexSpec (AttribLocation(..), IntegerHandling(KeepIntegral, ToFloat))
import Linear.Matrix(M44, (!*!))
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


data ShapeProgram =
  ShapeProgram
  {
    program              :: Program
  , pmvLocation          :: UniformLocation
  , meshLocation         :: AttribLocation
  , positionsLocation    :: AttribLocation
  , rotationsLocation    :: AttribLocation
  , scalesLocation       :: AttribLocation
  , colorsLocation       :: AttribLocation
  , meshDescription      :: (IntegerHandling, VertexArrayDescriptor GLfloat)
  , positionsDescription :: (IntegerHandling, VertexArrayDescriptor GLfloat)
  , rotationsDescription :: (IntegerHandling, VertexArrayDescriptor GLfloat)
  , scalesDescription    :: (IntegerHandling, VertexArrayDescriptor GLfloat)
  , colorsDescription    :: (IntegerHandling, VertexArrayDescriptor GLuint )
  }


prepareShapeProgram :: IO ShapeProgram
prepareShapeProgram =
  do

    program <- createProgram
    programSeparable program $=! True

    vertexShader <- createShader VertexShader
    shaderSourceBS vertexShader $=! vertexShaderSource
    compileShader vertexShader
    program `attachShader` vertexShader 

    linkProgram program

    let
      meshDescription      = (ToFloat     , VertexArrayDescriptor 3 Float       12 nullPtr)
      positionsDescription = (ToFloat     , VertexArrayDescriptor 3 Float       12 nullPtr)
      rotationsDescription = (ToFloat     , VertexArrayDescriptor 4 Float       16 nullPtr)
      scalesDescription    = (ToFloat     , VertexArrayDescriptor 3 Float       12 nullPtr)
      colorsDescription    = (KeepIntegral, VertexArrayDescriptor 1 UnsignedInt  4 nullPtr)

    pmvLocation       <- get $ uniformLocation program "projection_modelview"

    meshLocation      <- get $ attribLocation  program "mesh_position"
    positionsLocation <- get $ attribLocation  program "instance_position"
    rotationsLocation <- get $ attribLocation  program "instance_rotation"
    scalesLocation    <- get $ attribLocation  program "instance_scale"
    colorsLocation    <- get $ attribLocation  program "instance_color"

    return ShapeProgram{..}


deleteShapeProgram :: ShapeProgram
                   -> IO ()
deleteShapeProgram ShapeProgram{..} = deleteObjectName program


selectShapeProgram :: Maybe ShapeProgram
                   -> IO ()
selectShapeProgram = (currentProgram $=!) . fmap program


setProjectionModelView :: ShapeProgram
                       -> M44 GLfloat
                       -> M44 GLfloat
                       -> IO ()
setProjectionModelView ShapeProgram{..} projection modelView =
  do
    matrx <- makeMatrix projection modelView
    uniform pmvLocation $=! (matrx :: GLmatrix GLfloat)


setProjectionModelView' :: forall a . (MatrixComponent a, Num a)
                        => M44 a
                        -> M44 a
                        -> IO ()
setProjectionModelView' projection modelView =
  do
    matrx <- makeMatrix projection modelView
    matrix Nothing $=! (matrx :: GLmatrix a)


makeMatrix :: (MatrixComponent a, Num a, Matrix m)
           => M44 a
           -> M44 a
           -> IO (m a)
makeMatrix projection modelView =
  let
    (V4 (V4 a00 a01 a02 a03) (V4 a10 a11 a12 a13) (V4 a20 a21 a22 a23) (V4 a30 a31 a32 a33)) = projection !*! modelView
  in
    newMatrix RowMajor [a00, a01, a02, a03, a10, a11, a12, a13, a20, a21, a22, a23, a30, a31, a32, a33]


bindMesh :: ShapeProgram
         -> Maybe BufferObject
         -> IO ()
bindMesh ShapeProgram{..} = bindAttributes False meshLocation meshDescription 


bindPositions :: ShapeProgram
              -> Maybe BufferObject
              -> IO ()
bindPositions ShapeProgram{..} = bindAttributes True positionsLocation positionsDescription 


bindRotations :: ShapeProgram
              -> Maybe BufferObject
              -> IO ()
bindRotations ShapeProgram{..} = bindAttributes True rotationsLocation rotationsDescription 


bindScales :: ShapeProgram
           -> Maybe BufferObject
           -> IO ()
bindScales ShapeProgram{..} = bindAttributes True scalesLocation scalesDescription 


bindColors :: ShapeProgram
           -> Maybe BufferObject
           -> IO ()
bindColors ShapeProgram{..} = bindAttributes True colorsLocation colorsDescription 


bindAttributes :: Bool
               -> AttribLocation
               -> (IntegerHandling, VertexArrayDescriptor a)
               -> Maybe BufferObject
               -> IO ()
bindAttributes instanced location@(AttribLocation location') description (Just buffer) =
  do
    bindBuffer ArrayBuffer $=! Just buffer
    vertexAttribPointer location $=! description
    when instanced
     $ glVertexAttribDivisorARB location' 1
    vertexAttribArray location $=! Enabled
bindAttributes _ location _ Nothing = vertexAttribArray location $=! Disabled
