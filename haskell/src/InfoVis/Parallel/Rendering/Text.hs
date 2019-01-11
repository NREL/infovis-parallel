module InfoVis.Parallel.Rendering.Text (
  drawText
) where


import Graphics.Rendering.OpenGL (($=!), get)
import Graphics.Rendering.OpenGL.GL.CoordTrans (MatrixMode(..), Size(..), loadIdentity, matrixMode, preservingMatrix, viewport)
import Graphics.Rendering.OpenGL.GL.VertexSpec (Color4(..), color)
import Graphics.UI.GLUT.Fonts (StrokeFont(MonoRoman), fontHeight, renderString)
import Linear.Util.Graphics (toTranslation, toScale)
import Linear.V3 (V3(..))


drawText :: String
         -> IO ()
drawText "" = return ()
drawText text =
  preservingMatrix
    $ do
      (_, Size w h) <- get viewport
      matrixMode $=! Projection
      loadIdentity
      fh <- fontHeight MonoRoman
      color (Color4 1 1 0 0.5 :: Color4 Double)
      toTranslation (V3 (-0.975) 0.9 0 :: V3 Double)
      toScale $ V3 (fromIntegral h / fromIntegral w * 0.1 / fh) (0.1 / fh) 1
      renderString MonoRoman text
