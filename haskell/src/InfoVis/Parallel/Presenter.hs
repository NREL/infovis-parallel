{-# LANGUAGE DeriveGeneric    #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RecordWildCards  #-}


module InfoVis.Parallel.Presenter (
  presentDataset
) where


import Control.Lens.Lens ((&))
import Control.Lens.Setter ((.~))
import Control.Monad (ap)
import Control.Monad.Except (MonadError, MonadIO)
import Data.Aeson.Types (FromJSON, ToJSON)
import Data.Default (def)
import Data.ProtocolBuffers (encodeMessage)
import Data.Serialize (runPut)
import Data.Yaml.Config (loadYamlSettings, ignoreEnv)
import GHC.Generics (Generic)
import InfoVis (SeverityLog, guardIO)
import InfoVis.Parallel.Dataset (Dataset, readDataset)
import InfoVis.Parallel.Presenter.Grid (GridIdentifier, Presentable(..))
import InfoVis.Parallel.Presenter.Presentation (Presentation)
import InfoVis.Parallel.ProtoBuf (Request, upsert)
import InfoVis.Parallel.Types (DeltaGeometry, Geometry, Identifier, deltaGeometry)

import qualified Data.ByteString as BS (writeFile)


data Configuration =
  Configuration
  {
    dataset      :: Dataset
  , presentation :: Presentation
  }
    deriving (Eq, Generic, Read, Show)

instance FromJSON Configuration

instance ToJSON Configuration


presentDataset :: (MonadError String m, MonadIO m, SeverityLog m)
               => [FilePath]
               -> m ()
presentDataset configurationFiles =
  do
    Configuration{..} <- guardIO $ loadYamlSettings configurationFiles [] ignoreEnv
    _records <- readDataset dataset
    let
      nGrid = 1000000000000
      gridDisplay = zip [nGrid..] $ present presentation :: [(Identifier, (GridIdentifier, Geometry))]
--    gridIndex = second fst <$> gridDisplay :: [(Identifier, GridIdentifier)]
      gridGeometry = (deltaGeometry 1 . fst) `ap` (snd . snd) <$> gridDisplay :: [DeltaGeometry]
      request = def & upsert .~ gridGeometry :: Request
    guardIO
      $ BS.writeFile "test.pbb" 
      $ runPut
      $ encodeMessage request
    return ()
