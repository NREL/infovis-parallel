{-# LANGUAGE DeriveAnyClass   #-}
{-# LANGUAGE DeriveGeneric    #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RecordWildCards  #-}


module InfoVis.Parallel.Dataset (
  Dataset(..)
, VariableAlias
, Variable(..)
, RecordIdentifier
, Record
, readDataset
) where


import Control.Monad (when)
import Control.Monad.Except (MonadError, MonadIO)
import Control.Monad.Log (logCritical, logDebug, logInfo)
import Data.Aeson.Types (FromJSON(..), ToJSON(..))
import Data.Binary (Binary)
import Data.List.Split (splitOn)
import Data.List.Util (elemPermutation)
import Data.Maybe (fromJust, isNothing)
import GHC.Generics (Generic)
import InfoVis (SeverityLog, guardIO)


data Dataset =
  Dataset
  {
    datasetIdentifier :: String
  , variables         :: [Variable]
  , maxRecords        :: Maybe Int
  , chunkSize         :: Maybe Int
  }
    deriving (Binary, Eq, FromJSON, Generic, Ord, Read, Show, ToJSON)


data Variable =
  ContinuousVariable
  {
    variableAlias :: VariableAlias
  , variableName  :: String
  , units         :: Maybe String
  , lowerBound    :: Maybe Double
  , upperBound    :: Maybe Double
  , jitter        :: Maybe Double -- FIXME: Needs implementation.
  }
    deriving (Binary, Eq, FromJSON, Generic, Ord, Read, Show, ToJSON)


type VariableAlias = String


type RecordIdentifier = Int


type Record = [Double]


readDataset :: (MonadError String m, MonadIO m, SeverityLog m)
            => Dataset
            -> m [Record]
readDataset Dataset{..} =
  do
    logInfo $ "Reading dataset " ++ show datasetIdentifier ++ " . . ."
    (header : contents) <-
      guardIO
        $ fmap (splitOn "\t") . lines
        <$> readFile datasetIdentifier
    logDebug $ " . . . " ++ show (length contents) ++ " records."
    let
      reordering =
        elemPermutation header
          $ variableName
          <$> variables
      reorder = (<$> fromJust reordering) . (read .) . (!!)
    when (isNothing reordering)
      $ logCritical "readDataset: Missing variables."
    return $ reorder <$> contents