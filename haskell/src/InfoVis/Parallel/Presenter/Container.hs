{-# LANGUAGE DeriveAnyClass  #-}
{-# LANGUAGE DeriveGeneric   #-}
{-# LANGUAGE RecordWildCards #-}


module InfoVis.Parallel.Presenter.Container (
  Container(..)
) where


import Data.Aeson.Types (FromJSON(..), ToJSON(..))
import Data.Binary (Binary)
import GHC.Generics (Generic)
import InfoVis.Parallel.Dataset (Record, Variable)
import InfoVis.Parallel.Presenter.Extent (Extent, Scalable(..))
import InfoVis.Parallel.Presenter.Grid (Grid, GridDisplay, Presentable(..))
import InfoVis.Parallel.Presenter.Types (Projectable(..))
import InfoVis.Parallel.Types (Position)


data Container = -- FIXME: The dimensionality between extents and grids is not enforced to be consistent.  Can this be easily done at the type level?
    Singleton
    {
      extent  :: Extent
    , grid    :: Grid
    }
  | Array
    {
      extents :: [Extent]
    , grids   :: [Grid]
    }
  | Collection
    {
      extents    :: [Extent]
    , containeds :: [Container]
    }
    deriving (Binary, Eq, FromJSON, Generic, Ord, Read, Show, ToJSON)


instance Projectable Container where
  project Singleton{..}  variables record =                   scaleProject variables record  extent  grid
  project Array{..}      variables record = concat $ zipWith (scaleProject variables record) extents grids
  project Collection{..} variables record = concat $ zipWith (scaleProject variables record) extents containeds


scaleProject :: Projectable a
             => [Variable]
             -> Record
             -> Extent
             -> a
             -> [Position]
scaleProject variables record extent' grid' = scale extent' <$> project grid' variables record


instance Presentable Container where
  present Singleton{..}  =                  scalePresent extent  grid
  present Array{..}      = concat $ zipWith scalePresent extents grids
  present Collection{..} = concat $ zipWith scalePresent extents containeds


scalePresent :: Presentable a
             => Extent
             -> a
             -> GridDisplay
scalePresent = (. present) . scale
