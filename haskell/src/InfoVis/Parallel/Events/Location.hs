{-# LANGUAGE DeriveGeneric    #-}
{-# LANGUAGE Rank2Types       #-}
{-# LANGUAGE RecordWildCards  #-}


module InfoVis.Parallel.Events.Location (
  ViewerLocation
, OffsetLocation
, ToolLocation
) where


import Control.Lens.Lens (Lens', (&))
import Control.Lens.Getter ((^.))
import Control.Lens.Setter ((.~), (?~))
import Data.Aeson.Types (FromJSON, ToJSON)
import Data.Bifunctor (first, second)
import Data.Default (Default(..))
import GHC.Generics (Generic)
import InfoVis.Parallel.Events.Types (Behave(..), Visualization, offset, tool, viewer)
import InfoVis.Parallel.Types (PositionEuler, PositionRotation)
import InfoVis.Parallel.ProtoBuf (Request)
import Linear.Util (fromEulerd, toEulerd, toQuaternion, toPoint)
import Network.UI.Kafka.Types (Button(..), Event(..), Toggle(..))

import qualified InfoVis.Parallel.ProtoBuf as P (offsetSet, toolSet, viewSet)



data ViewerLocation =
  ViewerLocation
  {
    resetViewer   :: Button
  , initialViewer :: PositionEuler
  }
    deriving (Eq, Generic, Read, Show)

instance FromJSON ViewerLocation

instance ToJSON ViewerLocation

instance Behave ViewerLocation where

  initialize ViewerLocation{..} =
    viewer .~ initialViewer

  behave ViewerLocation{..} =
    handle resetViewer initialViewer viewer P.viewSet


data OffsetLocation =
  OffsetLocation
  {
    resetOffset   :: Button
  , initialOffset :: PositionEuler
  }
    deriving (Eq, Generic, Read, Show)

instance FromJSON OffsetLocation

instance ToJSON OffsetLocation

instance Behave OffsetLocation where

  initialize OffsetLocation{..} =
    offset .~ initialOffset
  
  behave OffsetLocation{..} =
    handle resetOffset initialOffset offset P.offsetSet


data ToolLocation =
  ToolLocation
  {
    resetTool   :: Button
  , initialTool :: PositionEuler
  }
    deriving (Eq, Generic, Read, Show)

instance FromJSON ToolLocation

instance ToJSON ToolLocation

instance Behave ToolLocation where

  initialize ToolLocation{..} =
    tool .~ initialTool

  behave ToolLocation{..} =
    handle resetTool initialTool tool P.toolSet


handle :: Button
       -> PositionEuler
       -> Lens' Visualization PositionEuler
       -> Lens' Request (Maybe PositionRotation)
       -> Event
       -> Visualization
       -> (Visualization, Request)
handle _ _ field set LocationEvent{..} visualization =
  let
    positionEuler = first (const $ toPoint location) $ visualization ^. field
  in
    (
      visualization & field .~ positionEuler
    , def & set ?~ second fromEulerd positionEuler
    )
handle _ _ field set OrientationEvent{..} visualization =
  let
    positionEuler = second (const . toEulerd $ toQuaternion orientation) $ visualization ^. field
  in
    (
      visualization & field .~ positionEuler
    , def & set ?~ second fromEulerd positionEuler
    )
handle b initial field set (ButtonEvent (b', Down)) visualization
  | b == b'   = (visualization & field .~ initial, def & set ?~ second fromEulerd initial)
  | otherwise = (visualization, def)
handle _ _ _ _ _ visualization = (visualization, def)
