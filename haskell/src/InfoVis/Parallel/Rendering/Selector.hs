module InfoVis.Parallel.Rendering.Selector (
  createSelector
, prepareSelector
, drawSelector
) where


import Graphics.Rendering.OpenGL.GL.Tensor (Vector3(..), Vector4(..), Vertex3(..))
import InfoVis.Parallel.NewTypes (PositionRotation)
import InfoVis.Parallel.Rendering.Buffers (ShapeBuffer, createShapeBuffer, drawInstances, insertPositions, prepareShapeBuffer, updateColor, updateScales, updatePositions, updateRotations)
import InfoVis.Parallel.Rendering.NewShapes (cone)
import InfoVis.Parallel.Rendering.Program (ShapeProgram)
import Linear.Affine (Point(..))
import Linear.Quaternion (Quaternion(..))
import Linear.V3 (V3(..))


createSelector :: ShapeProgram
               -> ShapeBuffer
createSelector =
    updateColor     (1, 0xFF99007F)
  . updateScales    (1, [Vector3 0.05 0.05 0.05])
  . updateRotations (1, [Vector4 1 0 0 0])
  . insertPositions (1, [Vertex3 0 0 0])
  . flip createShapeBuffer 
    (cone 1 1)


prepareSelector :: PositionRotation
                -> ShapeBuffer
                -> IO ShapeBuffer
prepareSelector (P (V3 px py pz), Quaternion rw (V3 rx ry rz)) =
  prepareShapeBuffer
    . updateRotations (1, [realToFrac <$> Vector4 rx ry rz rw])
    . updatePositions (1, [realToFrac <$> Vertex3 px py pz   ])


drawSelector :: ShapeBuffer
             -> IO ()
drawSelector = drawInstances
