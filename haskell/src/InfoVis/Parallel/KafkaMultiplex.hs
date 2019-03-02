{-# LANGUAGE DeriveGeneric    #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE Rank2Types       #-}
{-# LANGUAGE RecordWildCards  #-}


module InfoVis.Parallel.KafkaMultiplex (
  Device(..)
, Behavior(..)
, multiplexKafka
) where


import Control.Concurrent.Chan (Chan, newChan, writeChan)
import Control.Concurrent.MVar (MVar, newMVar, modifyMVar_, putMVar, takeMVar)
import Control.Lens.Lens (Lens', lens, (&))
import Control.Lens.Getter ((^.))
import Control.Lens.Setter ((.~), (?~))
import Control.Monad (unless, void)
import Control.Monad.Except (MonadError, MonadIO, liftEither)
import Control.Monad.Log (Severity(..), logInfo)
import Data.Aeson.Types (FromJSON, ToJSON)
import Data.Bifunctor (bimap, first, second)
import Data.Default (Default(..))
import Data.Yaml (decodeFileEither)
import GHC.Generics (Generic)
import InfoVis (LoggerIO, SeverityLog, forkLoggedIO, guardIO, logIO, makeLogger)
import InfoVis.Parallel.NewTypes (Frame, PositionEuler, PositionRotation)
import InfoVis.Parallel.ProtoBuf (Request)
import InfoVis.Parallel.ProtoBuf.Sink (kafkaSink)
import Linear.Affine ((.+^))
import Linear.Util (fromEulerd, toEulerd, toQuaternion, toPoint)
import Linear.V3 (V3(..))
import Linear.Vector ((^+^), (*^), zero)
import Network.UI.Kafka (Sensor, TopicConnection(..), consumerLoop)
import Network.UI.Kafka.Types (Button(..), Event(..), Modifiers(..),  SpecialKey(..), Toggle(..))

import qualified InfoVis.Parallel.ProtoBuf as P (display, frameShow, offsetSet, toolSet, viewSet)


modifyMVar' :: MVar a
            -> (a -> a)
            -> IO ()
modifyMVar' = (. (return .)) . modifyMVar_


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


multiplexKafka :: (MonadError String m, MonadIO m, SeverityLog m)
               => (String, Int)
               -> String
               -> String
               -> [FilePath]
               -> m ()
multiplexKafka address client topic configurations =
  do

    visualizationMVar <- guardIO $ newMVar def

    (logChannel, logger) <- makeLogger

    requestChannel  <- guardIO newChan

    sequence_
      [
        void
          . forkLoggedIO logChannel
          $ do
            createDevice (logIO logChannel) requestChannel visualizationMVar configuration
            return False
      |
        configuration <- configurations
      ]

    void
      . forkLoggedIO logChannel
      $ do
        kafkaSink (logIO logChannel) requestChannel TopicConnection{..}
        return False

    logger


createDevice :: (MonadError String m, MonadIO m, SeverityLog m)
             => LoggerIO
             -> Chan Request
             -> MVar Visualization
             -> FilePath
             -> m ()
createDevice logger requestChannel visualizationMVar configuration =
  do
    logInfo $ "Reading device configuration from " ++ show configuration ++ " . . ."
    Device{..}  <-
      liftEither . either (Left . show) Right
        =<< guardIO (decodeFileEither configuration)
    guardIO
      $ mapM_ (flip initializeBehavior visualizationMVar . snd) handlers
    let
      TopicConnection{..} = device
      (host, port) = address
    logInfo $ "Opening Kafka topic " ++ topic ++ " on " ++ host ++ ":" ++ show port ++ " with client " ++ client ++ " . . ."
    (_, loop) <-
      guardIO
        .  consumerLoop device
        $ \sensor event ->
          do
            logger Debug $ "Received from sensor " ++ sensor ++ ": " ++ show event
            sequence_
              [
                do
                  visualization <- takeMVar visualizationMVar
                  let
                    (visualization', request) = behave behavior event visualization
                  putMVar visualizationMVar visualization'   
                  unless (visualization == visualization')
                    $ writeChan requestChannel request
              |
                (sensor', behavior) <- handlers
              , sensor == sensor'
              ]
    liftEither
      .   first show
      =<< guardIO loop
    logInfo $ "Closing connection to Kafka topic " ++ topic ++ " on " ++ host ++ ":" ++ show port ++ " . . ."


data Device =
  Device
  {
    device  :: TopicConnection
  , handlers :: [(Sensor, Behavior)]
  }
    deriving (Eq, Generic, Read, Show)

instance FromJSON Device

instance ToJSON Device


data Behavior =
    Typing
  | KeyFrame
    {
      nextFrame     :: Either SpecialKey Char
    , previousFrame :: Either SpecialKey Char
    , setFrame      :: [(Frame, Either SpecialKey Char)]
    }
  | KeyMovement
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
  | ViewerLocation
    {
      resetButton   :: Maybe Int
    , initialViewer :: PositionEuler
    }
  | OffsetLocation
    {
      resetButton   :: Maybe Int
    , initialOffset :: PositionEuler
    }
  | ToolLocation
    {
      resetButton   :: Maybe Int
    , initialTool   :: PositionEuler
    }
    deriving (Eq, Generic, Read, Show)

instance FromJSON Behavior

instance ToJSON Behavior


initializeBehavior :: Behavior
                   -> MVar Visualization
                   -> IO ()

initializeBehavior Typing _ =
  return ()

initializeBehavior KeyFrame{} visualizationMVar =
  modifyMVar' visualizationMVar
    $ frame .~ 1

initializeBehavior KeyMovement{..} visualizationMVar =
  modifyMVar' visualizationMVar
    $ (tool   .~ initialTool)
    . (offset .~ initialOffset)

initializeBehavior ViewerLocation{..} visualizationMVar =
  modifyMVar' visualizationMVar
    $ viewer .~ initialViewer

initializeBehavior OffsetLocation{..} visualizationMVar =
  modifyMVar' visualizationMVar
    $ viewer .~ initialOffset

initializeBehavior ToolLocation{..} visualizationMVar =
  modifyMVar' visualizationMVar
    $ viewer .~ initialTool


behave :: Behavior
       -> Event
       -> Visualization
       -> (Visualization, Request)

behave Typing KeyEvent{..} visualization =
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

behave keyFrame'@KeyFrame{} KeyEvent{..} visualization =
  keyFrame keyFrame' (Right key) visualization
behave keyFrame'@KeyFrame{} SpecialKeyEvent{..} visualization =
  keyFrame keyFrame' (Left specialKey) visualization

behave keyMovement'@KeyMovement{} KeyEvent{..} visualization =
  keyMovement keyMovement' (Right key) modifiers visualization
behave keyMovement'@KeyMovement{} SpecialKeyEvent{..} visualization =
  keyMovement keyMovement' (Left specialKey) modifiers visualization

behave ViewerLocation{..} locationEvent visualization =
  relocation resetButton initialViewer viewer P.viewSet locationEvent visualization
behave OffsetLocation{..} locationEvent visualization =
  relocation resetButton initialOffset offset P.offsetSet locationEvent visualization
behave ToolLocation{..} locationEvent visualization =
  relocation resetButton initialTool tool P.toolSet locationEvent visualization

behave _ _ visualization = (visualization, def)


keyMovement :: Behavior
            -> Either SpecialKey Char
            -> Maybe Modifiers
            -> Visualization
            -> (Visualization, Request)
keyMovement KeyMovement{..} key' modifiers' visualization@Visualization{..} =
  let
    motion =
      head' zero
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
      head' zero
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
keyMovement _ _ _ visualization = (visualization, def)


keyFrame :: Behavior
         -> Either SpecialKey Char
         -> Visualization
         -> (Visualization, Request)
keyFrame KeyFrame{..} key' visualization =
  let
    frame'
      | key' == nextFrame     = visualization ^. frame + 1
      | key' == previousFrame = visualization ^. frame - 1
      | otherwise             = head' (visualization ^. frame) $ fst <$> filter ((key' ==) . snd) setFrame
  in
    (
      visualization & frame .~ frame'
    , def & P.frameShow .~ frame'
    )
keyFrame _ _ visualization = (visualization, def)


relocation :: Maybe Int
           -> PositionEuler
           -> Lens' Visualization PositionEuler
           -> Lens' Request (Maybe PositionRotation)
           -> Event
           -> Visualization
           -> (Visualization, Request)
relocation _ _ field set LocationEvent{..} visualization =
  let
    positionEuler = first (const $ toPoint location) $ visualization ^. field
  in
    (
      visualization & field .~ positionEuler
    , def & set ?~ second fromEulerd positionEuler
    )
relocation _ _ field set OrientationEvent{..} visualization =
  let
    positionEuler = second (const . toEulerd $ toQuaternion orientation) $ visualization ^. field
  in
    (
      visualization & field .~ positionEuler
    , def & set ?~ second fromEulerd positionEuler
    )
relocation (Just i) initial field set (ButtonEvent (IndexButton j, Down)) visualization
  | i == j    = (visualization & field .~ initial, def & set ?~ second fromEulerd initial)
  | otherwise = (visualization, def)
relocation _ _ _ _ _ visualization = (visualization, def)



head' :: a
      -> [a]
      -> a
head' x []      = x
head' _ (x : _) = x
