{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric  #-}


module InfoVis.Parallel.Presenter.Link (
  LinkAlias
, Link(..)
) where


import Data.Aeson.Types (FromJSON(..), ToJSON(..))
import Data.Binary (Binary)
import GHC.Generics (Generic)
import InfoVis.Parallel.Presenter.Grid (GridAlias, Styling)


type LinkAlias = String


data Link =
    Point
    {
      linkAlias  :: LinkAlias
    , linkedGrid :: GridAlias
    , styling    :: Styling
    }
  | Polyline
    {
      linkAlias   :: LinkAlias
    , linkedGrids :: [GridAlias]
    , styling     :: Styling
    }
    deriving (Binary, Eq, FromJSON, Generic, Ord, Read, Show, ToJSON)
