{-# LANGUAGE DeriveGeneric    #-}


module InfoVis.Parallel.Events.Types (
  Visualization
, frame
, shown
, viewer
, tool
, offset
, Behavior(..)
, Behave(..)
) where


import Control.Lens.Lens (Lens', lens)
import Data.Aeson.Types (FromJSON, ToJSON)
import Data.Default (Default(..))
import GHC.Generics (Generic)
import InfoVis.Parallel.NewTypes (Frame, PositionEuler)
import InfoVis.Parallel.ProtoBuf (Request)
import Linear.Vector (zero)
import Network.UI.Kafka.Types (Event)


data Visualization =
  Visualization
  {
    _frame  :: Frame
  , _shown  :: String
  , _viewer :: PositionEuler
  , _tool   :: PositionEuler
  , _offset :: PositionEuler
  }
   deriving (Eq, Ord, Read, Show)

instance Default Visualization where
  def =
    Visualization
      {
        _frame  = 1
      , _shown  = ""
      , _viewer = (zero, zero)
      , _tool   = (zero, zero)
      , _offset = (zero, zero)
      }


frame :: Lens' Visualization Frame
frame = lens _frame $ \s x -> s {_frame = x}


shown :: Lens' Visualization String
shown = lens _shown $ \s x -> s {_shown = x}


viewer :: Lens' Visualization PositionEuler
viewer = lens _viewer $ \s x -> s {_viewer = x}


tool :: Lens' Visualization PositionEuler
tool = lens _tool $ \s x -> s {_tool = x}


offset :: Lens' Visualization PositionEuler
offset = lens _offset $ \s x -> s {_offset = x}


data Behavior =
  NullBehavior
    deriving (Eq, Generic, Read, Show)

instance FromJSON Behavior

instance ToJSON Behavior


class Behave a where
  initialize :: a -> Visualization -> Visualization
  behave :: a -> Event -> Visualization -> (Visualization, Request)
