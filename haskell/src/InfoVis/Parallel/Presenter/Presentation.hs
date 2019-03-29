{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric  #-}


module InfoVis.Parallel.Presenter.Presentation (
  Presentation(..)
) where


import Data.Aeson.Types (FromJSON(..), ToJSON(..))
import Data.Binary (Binary)
import GHC.Generics (Generic)
import InfoVis.Parallel.Dataset (VariableAlias)
import InfoVis.Parallel.Presenter.Container (Container)
import InfoVis.Parallel.Presenter.Link (Link)


data Presentation =
  Presentation
  {
    containers   :: [Container]
  , links        :: [Link]
  , animationKey :: Maybe VariableAlias
  , uniqueKey    :: Maybe VariableAlias
  }
    deriving (Binary, Eq, FromJSON, Generic, Ord, Read, Show, ToJSON)
