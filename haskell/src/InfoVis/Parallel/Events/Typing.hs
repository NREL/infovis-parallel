{-# LANGUAGE DeriveGeneric    #-}
{-# LANGUAGE RecordWildCards  #-}


module InfoVis.Parallel.Events.Typing (
  Typing
) where


import Control.Lens.Lens ((&))
import Control.Lens.Getter ((^.))
import Control.Lens.Setter ((.~), (?~))
import Data.Aeson.Types (FromJSON, ToJSON)
import Data.Default (Default(..))
import GHC.Generics (Generic)
import InfoVis.Parallel.Events.Types (Behave(..), shown)
import Network.UI.Kafka.Types (Event(..))

import qualified InfoVis.Parallel.ProtoBuf as P (display)


data Typing =
  Typing
    deriving (Eq, Generic, Read, Show)

instance FromJSON Typing

instance ToJSON Typing

instance Behave Typing where

  initialize _ = id

  behave _ KeyEvent{..} visualization =
    let
      text =
        if key == '\n'
          then ""
          else visualization ^. shown ++ [key]
    in
      (
        visualization & shown .~ text
      , def & P.display ?~ text
      )
  behave _ _ visualization = (visualization, def)
