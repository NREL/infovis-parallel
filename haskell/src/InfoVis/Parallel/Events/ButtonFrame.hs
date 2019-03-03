{-# LANGUAGE DeriveGeneric    #-}
{-# LANGUAGE RecordWildCards  #-}


module InfoVis.Parallel.Events.ButtonFrame (
  ButtonFrame
) where


import Control.Lens.Lens ((&))
import Control.Lens.Getter ((^.))
import Control.Lens.Setter ((.~))
import Data.Aeson.Types (FromJSON, ToJSON)
import Data.Default (Default(..))
import Data.List.Util (headWith)
import GHC.Generics (Generic)
import InfoVis.Parallel.Events.Types (Behave(..), frame)
import InfoVis.Parallel.Types (Frame)
import Network.UI.Kafka.Types (Button(..), Event(..), Toggle(..))

import qualified InfoVis.Parallel.ProtoBuf as P (frameShow)


data ButtonFrame =
  ButtonFrame
  {
    nextButton     :: Button
  , previousButton :: Button
  , setButton      :: [(Frame, Button)]
  }
    deriving (Eq, Generic, Read, Show)

instance FromJSON ButtonFrame

instance ToJSON ButtonFrame

instance Behave ButtonFrame where

  initialize ButtonFrame{..} =
    frame .~ 1

  behave ButtonFrame{..} (ButtonEvent (button', Down)) visualization =
    let
      frame'
        | button' == nextButton     = visualization ^. frame + 1
        | button' == previousButton = visualization ^. frame - 1
        | otherwise                 = headWith (visualization ^. frame)
                                        $ fst
                                        <$> filter ((button' ==) . snd) setButton
    in
      (
        visualization & frame .~ frame'
      , def & P.frameShow .~ frame'
      )
  behave _ _ visualization = (visualization, def)
