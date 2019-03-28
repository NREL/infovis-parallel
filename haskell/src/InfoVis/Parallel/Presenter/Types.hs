{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric  #-}


module InfoVis.Parallel.Presenter.Types (
  Axis(..)
, Axes1D
, Axes2D
, Axes3D
, GridAlias
, Grid(..)
, GriddedPosition
, Extent(..)
, Container(..)
, LinkAlias
, Link(..)
, TimeAlias
, Styling(..)
, Presentation(..)
) where


import Data.Aeson.Types (FromJSON(..), ToJSON(..))
import Data.Binary (Binary)
import GHC.Generics (Generic)
import InfoVis.Parallel.Types (Color, Position)
import InfoVis.Parallel.Dataset (VariableAlias)
import Linear.Util.Instances ()
import Linear.V1 (V1)
import Linear.V2 (V2)
import Linear.V3 (V3)


{-# ANN module "HLint: ignore Use newtype instead of data" #-}


type GridAlias = String


data Axis =
  Axis
  {
    axisVariable :: VariableAlias
  }
  deriving (Binary, Eq, FromJSON, Generic, Ord, Read, Show, ToJSON)


type Axes1D = V1 Axis


type Axes2D = V2 Axis


type Axes3D = V3 Axis


data Grid =
    LineGrid
    {
      gridAlias   :: GridAlias
    , axes1D      :: Axes1D
    , divisions   :: Int
    , lineStyling :: Styling
    , labelColor  :: Color
    , labelSize   :: Double
    }
  | RectangleGrid
    {
      gridAlias   :: GridAlias
    , axes2D      :: Axes2D
    , divisions   :: Int
    , lineStyling :: Styling
    , faceStyling :: Styling
    , labelColor  :: Color
    , labelSize   :: Double
    }
  | BoxGrid
    {
      gridAlias   :: GridAlias
    , axes3D      :: Axes3D
    , divisions   :: Int
    , lineStyling :: Styling
    , faceStyling :: Styling
    , labelColor  :: Color
    , labelSize   :: Double
    }
    deriving (Binary, Eq, FromJSON, Generic, Ord, Read, Show, ToJSON)


type GriddedPosition = (GridAlias, Position)


data Extent =
    Extent1D
    {
      origin  :: Position
    , cornerX :: Position
    }
  | Extent2D
    {
      origin  :: Position
    , cornerX :: Position
    , cornerY :: Position
    }
  | Extent3D
    {
      origin  :: Position
    , cornerX :: Position
    , cornerY :: Position
    , cornerZ :: Position
    }
    deriving (Binary, Eq, FromJSON, Generic, Ord, Read, Show, ToJSON)


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
    

type LinkAlias = String


data Link =
    Point
    {
      linkAlias  :: LinkAlias
    , linkedGrid :: GridAlias
    , styling    :: Styling
    }
  | Polyline
    {
      linkAlias   :: LinkAlias
    , linkedGrids :: [GridAlias]
    , styling     :: Styling
    }
    deriving (Binary, Eq, FromJSON, Generic, Ord, Read, Show, ToJSON)


type TimeAlias = String


data Styling =
    Styling
    {
      normalColor    :: Color
    , selectColor    :: Color
    , highlightColor :: Color
    }
    deriving (Binary, Eq, FromJSON, Generic, Ord, Read, Show, ToJSON)


data Presentation =
  Presentation
  {
    containers   :: [Container]
  , links        :: [Link]
  , animationKey :: Maybe VariableAlias
  , uniqueKey    :: Maybe VariableAlias
  }
    deriving (Binary, Eq, FromJSON, Generic, Ord, Read, Show, ToJSON)
