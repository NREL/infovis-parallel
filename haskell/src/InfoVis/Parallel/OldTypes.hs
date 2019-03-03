{-# LANGUAGE DeriveAnyClass     #-}
{-# LANGUAGE DeriveGeneric      #-}


module InfoVis.Parallel.Types (
  Location
, Color
, Coloring(..)
) where


import Control.DeepSeq (NFData)
import Data.Aeson.Types (FromJSON, ToJSON)
import Data.Binary (Binary)
import GHC.Generics (Generic)
import Graphics.Rendering.OpenGL (GLfloat)
import Graphics.Rendering.OpenGL.GL.VertexSpec (Color4(..))
import Linear.Affine (Point(..))
import Linear.V3 (V3)


type Location = Point V3 Double


type Color = Color4 GLfloat

data Coloring =
    NormalColoring
  | SelectColoring
  | HighlightColoring
  deriving (Binary, Bounded, Enum, Eq, FromJSON, Generic, NFData, Ord, Read, Show, ToJSON)
