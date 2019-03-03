{-# LANGUAGE DeriveGeneric    #-}
{-# LANGUAGE RecordWildCards  #-}


module InfoVis.Parallel.Events.KeyMovement (
  KeyMovement
) where


import Control.Lens.Lens ((&))
import Control.Lens.Getter ((^.))
import Control.Lens.Setter ((.~), (?~))
import Data.Aeson.Types (FromJSON, ToJSON)
import Data.Bifunctor (bimap, second)
import Data.Default (Default(..))
import Data.List.Util (headWith)
import GHC.Generics (Generic)
import InfoVis.Parallel.Events.Types (Behave(..), Visualization, offset, tool)
import InfoVis.Parallel.Types (PositionEuler)
import InfoVis.Parallel.ProtoBuf (Request)
import Linear.Affine ((.+^))
import Linear.Util (fromEulerd)
import Linear.V3 (V3(..))
import Linear.Vector ((^+^), (*^), zero)
import Network.UI.Kafka.Types (Event(..), Modifiers(..),  SpecialKey(..))

import qualified InfoVis.Parallel.ProtoBuf as P (offsetSet, toolSet)


data KeyMovement =
  KeyMovement
  {
    offsetModifiers        :: Maybe Modifiers
  , toolModifiers          :: Maybe Modifiers
  , deltaOffsetPosition    :: Double
  , deltaToolPosition      :: Double
  , deltaRotation          :: Double
  , moveRightward          :: Either SpecialKey Char
  , moveLeftward           :: Either SpecialKey Char
  , moveForward            :: Either SpecialKey Char
  , moveBackward           :: Either SpecialKey Char
  , moveUpward             :: Either SpecialKey Char
  , moveDownward           :: Either SpecialKey Char
  , rotateForward          :: Either SpecialKey Char
  , rotateBackward         :: Either SpecialKey Char
  , rotateClockwise        :: Either SpecialKey Char
  , rotateCounterclockwise :: Either SpecialKey Char
  , rotateRightward        :: Either SpecialKey Char
  , rotateLeftward         :: Either SpecialKey Char
  , resetOffset            :: Either SpecialKey Char
  , resetTool              :: Either SpecialKey Char
  , initialOffset          :: PositionEuler
  , initialTool            :: PositionEuler
  }
    deriving (Eq, Generic, Read, Show)

instance FromJSON KeyMovement

instance ToJSON KeyMovement

instance Behave KeyMovement where

  initialize KeyMovement{..} =
    (tool   .~ initialTool)
    . (offset .~ initialOffset)

  behave keyMovement' KeyEvent{..} visualization =
    handle keyMovement' (Right key) modifiers visualization
  behave keyMovement' SpecialKeyEvent{..} visualization =
    handle keyMovement' (Left specialKey) modifiers visualization
  behave _ _ visualization = (visualization, def)


handle :: KeyMovement
       -> Either SpecialKey Char
       -> Maybe Modifiers
       -> Visualization
       -> (Visualization, Request)
handle KeyMovement{..} key' modifiers' visualization =
  let
    motion =
      headWith zero
        $ snd
        <$> filter ((key' ==) . fst)
        [
          (moveRightward, V3   1   0   0 )
        , (moveLeftward , V3 (-1)  0   0 )
        , (moveForward  , V3   0   0 (-1))
        , (moveBackward , V3   0   0   1 )
        , (moveUpward   , V3   0   1   0 )
        , (moveDownward , V3   0 (-1)  0 )
        ]
    rotation =
      headWith zero
        $ snd
        <$> filter ((key' ==) . fst)
        [
          (rotateForward         , V3   1   0    0 )
        , (rotateBackward        , V3 (-1)  0    0 )
        , (rotateClockwise       , V3   0   1    0 )
        , (rotateCounterclockwise, V3   0 (-1)   0 )
        , (rotateLeftward        , V3   0   0    1 )
        , (rotateRightward       , V3   0   0  (-1))
        ]
    offset'
      | key'       == resetOffset     = initialOffset
      | modifiers' == offsetModifiers = bimap
                                          (.+^ (deltaOffsetPosition *^ motion  ))
                                          (^+^ (deltaRotation       *^ rotation))
                                          $ visualization ^. offset
      | otherwise                     =  visualization ^. offset
    tool'
      | key'       == resetTool       = initialTool
      | modifiers' == toolModifiers   = bimap
                                          (.+^ (deltaToolPosition *^ motion  ))
                                          (^+^ (deltaRotation     *^ rotation))
                                          $ visualization ^. tool
      | otherwise                     = visualization ^. tool
  in
   (
      visualization
        & offset .~ offset'
        & tool   .~ tool'  
    , def & P.offsetSet ?~ second fromEulerd offset'
          & P.toolSet   ?~ second fromEulerd tool'
    )
