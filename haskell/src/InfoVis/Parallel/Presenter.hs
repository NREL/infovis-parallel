{-# LANGUAGE DeriveGeneric    #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RecordWildCards  #-}


module InfoVis.Parallel.Presenter (
  presentDataset
) where


import Control.Monad.Except (MonadError, MonadIO)
import Data.Aeson.Types (FromJSON, ToJSON)
import Data.Yaml.Config (loadYamlSettings, ignoreEnv)
import GHC.Generics (Generic)
import InfoVis (SeverityLog, guardIO)
import InfoVis.Parallel.Dataset (Dataset, readDataset)
import InfoVis.Parallel.Presenter.Types (Presentation)


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
    records <- readDataset dataset
    guardIO $ print presentation
    return ()
