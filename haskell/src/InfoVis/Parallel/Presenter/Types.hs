{-# LANGUAGE DeriveAnyClass    #-}
{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE FlexibleInstances #-}


module InfoVis.Parallel.Presenter.Types (
  Projectable(..)
, Axis(..)
, Axes1D
, Axes2D
, Axes3D
, TimeAlias
, Styling(..)
) where


import Control.Lens.Operators ((??))
import Data.Aeson.Types (FromJSON(..), ToJSON(..))
import Data.Binary (Binary)
import GHC.Generics (Generic)
import InfoVis.Parallel.Types (Color, Position)
import InfoVis.Parallel.Dataset (Record, Variable, VariableAlias, quantify)
import Linear.Util.Instances ()
import Linear.Affine (Point(..))
import Linear.V1 (V1(..))
import Linear.V2 (V2(..))
import Linear.V3 (V3(..))


{-# ANN module "HLint: ignore Use newtype instead of data" #-}


class Projectable a where
  project :: a -> [Variable] -> Record -> [Position]


data Axis =
  Axis
  {
    axisVariable :: VariableAlias
  }
  deriving (Binary, Eq, FromJSON, Generic, Ord, Read, Show, ToJSON)


type Axes1D = V1 Axis

instance Projectable Axes1D where
  project (V1 ax) variables =
    let
      px = axisVariable ax `quantify` variables
      py = const 0
      pz = const 0
    in
      (: []) . P . (V3 px py pz ??)


type Axes2D = V2 Axis

instance Projectable Axes2D where
  project (V2 ax ay) variables =
    let
      px = axisVariable ax `quantify` variables
      py = axisVariable ay `quantify` variables
      pz = const 0
    in
      (: []) . P . (V3 px py pz ??)


type Axes3D = V3 Axis

instance Projectable Axes3D where
  project (V3 ax ay az) variables =
    let
      px = axisVariable ax `quantify` variables
      py = axisVariable ay `quantify` variables
      pz = axisVariable az `quantify` variables
    in
      (: []) . P . (V3 px py pz ??)


type TimeAlias = String


data Styling =
  Styling
  {
    normalColor    :: Color
  , selectColor    :: Color
  , highlightColor :: Color
  , thickness      :: Double
  }
    deriving (Binary, Eq, FromJSON, Generic, Ord, Read, Show, ToJSON)
