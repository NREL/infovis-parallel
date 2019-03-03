{-# LANGUAGE DeriveGeneric    #-}
{-# LANGUAGE RecordWildCards  #-}


module InfoVis.Parallel.Events.KeyFrame (
  KeyFrame
) where


import Control.Lens.Lens ((&))
import Control.Lens.Getter ((^.))
import Control.Lens.Setter ((.~))
import Data.Aeson.Types (FromJSON, ToJSON)
import Data.Default (Default(..))
import Data.List.Util (headWith)
import GHC.Generics (Generic)
import InfoVis.Parallel.Events.Types (Behave(..), frame, Visualization)
import InfoVis.Parallel.NewTypes (Frame)
import InfoVis.Parallel.ProtoBuf (Request)
import Network.UI.Kafka.Types (Event(..), SpecialKey(..), Toggle(..))

import qualified InfoVis.Parallel.ProtoBuf as P (frameShow)


data KeyFrame =
  KeyFrame
  {
    nextKey     :: Either SpecialKey Char
  , previousKey :: Either SpecialKey Char
  , setKey      :: [(Frame, Either SpecialKey Char)]
  }
    deriving (Eq, Generic, Read, Show)

instance FromJSON KeyFrame

instance ToJSON KeyFrame

instance Behave KeyFrame where

  initialize _ = frame .~ 1

  behave keyFrame'@KeyFrame{} (KeyEvent key Nothing _ _) visualization =
    handle keyFrame' (Right key) visualization
  behave keyFrame'@KeyFrame{} (KeyEvent key (Just Down) _ _) visualization =
    handle keyFrame' (Right key) visualization
  behave keyFrame'@KeyFrame{} (SpecialKeyEvent specialKey Nothing _ _) visualization =
    handle keyFrame' (Left specialKey) visualization
  behave keyFrame'@KeyFrame{} (SpecialKeyEvent specialKey (Just Down) _ _) visualization =
    handle keyFrame' (Left specialKey) visualization
  behave _ _ visualization = (visualization, def)


handle :: KeyFrame
       -> Either SpecialKey Char
       -> Visualization
       -> (Visualization, Request)
handle KeyFrame{..} key' visualization =
  let
    frame'
      | key' == nextKey     = visualization ^. frame + 1
      | key' == previousKey = visualization ^. frame - 1
      | otherwise           = headWith (visualization ^. frame)
                                $ fst
                                <$> filter ((key' ==) . snd) setKey
  in
    (
      visualization & frame .~ frame'
    , def & P.frameShow .~ frame'
    )
