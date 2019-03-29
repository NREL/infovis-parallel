{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric  #-}


module InfoVis.Parallel.Presenter.Extent (
  Extent(..)
) where


import Data.Aeson.Types (FromJSON(..), ToJSON(..))
import Data.Binary (Binary)
import GHC.Generics (Generic)
import InfoVis.Parallel.Types (Position)
import Linear.Util.Instances ()


data Extent =
    Extent1D
    {
      origin  :: Position
    , cornerX :: Position
    }
  | Extent2D
    {
      origin  :: Position
    , cornerX :: Position
    , cornerY :: Position
    }
  | Extent3D
    {
      origin  :: Position
    , cornerX :: Position
    , cornerY :: Position
    , cornerZ :: Position
    }
    deriving (Binary, Eq, FromJSON, Generic, Ord, Read, Show, ToJSON)

