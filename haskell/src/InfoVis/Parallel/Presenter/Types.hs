{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric  #-}


module InfoVis.Parallel.Presenter.Types (
  Axis(..)
, Axes1D
, Axes2D
, Axes3D
, TimeAlias
, Styling(..)
) where


import Data.Aeson.Types (FromJSON(..), ToJSON(..))
import Data.Binary (Binary)
import GHC.Generics (Generic)
import InfoVis.Parallel.Types (Color)
import InfoVis.Parallel.Dataset (VariableAlias)
import Linear.Util.Instances ()
import Linear.V1 (V1)
import Linear.V2 (V2)
import Linear.V3 (V3)


{-# ANN module "HLint: ignore Use newtype instead of data" #-}


data Axis =
  Axis
  {
    axisVariable :: VariableAlias
  }
  deriving (Binary, Eq, FromJSON, Generic, Ord, Read, Show, ToJSON)


type Axes1D = V1 Axis


type Axes2D = V2 Axis


type Axes3D = V3 Axis


type TimeAlias = String


data Styling =
  Styling
  {
    normalColor    :: Color
  , selectColor    :: Color
  , highlightColor :: Color
  }
    deriving (Binary, Eq, FromJSON, Generic, Ord, Read, Show, ToJSON)
