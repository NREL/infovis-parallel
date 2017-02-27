{-# LANGUAGE DeriveGeneric #-}


module InfoVis.Parallel.Types.Scaffold (
  Axis(..)
, Axes1D
, Axes2D
, Axes3D
, GridAlias
, Grid(..)
, GriddedLocation
, Extent(..)
, Container(..)
, LinkAlias
, Link(..)
, Characteristic(..)
, Presentation(..)
, WorldExtent(..)
, World(..)
) where


import Data.Aeson.Types (FromJSON(..), ToJSON(..))
import GHC.Generics (Generic)
import InfoVis.Parallel.Types (Color, Location)
import InfoVis.Parallel.Types.Dataset (VariableAlias)
import Linear.V1 (V1)
import Linear.V2 (V2)
import Linear.V3 (V3)


type GridAlias = String


data Axis =
  Axis
  {
    axisVariable :: VariableAlias
  }
  deriving (Eq, Generic, Read, Show)

instance FromJSON Axis

instance ToJSON Axis


type Axes1D = V1 Axis


type Axes2D = V2 Axis


type Axes3D = V3 Axis


data Grid =
    LineGrid
    {
      gridAlias           :: GridAlias
    , axes1D              :: Axes1D
    , divisions           :: Int
    , lineCharacteristics :: [Characteristic]
    , labelColor          :: Color            -- FIXME: Needs implementation.
    , labelSize           :: Double           -- FIXME: Needs implementation.
    }
  | RectangleGrid
    {
      gridAlias           :: GridAlias
    , axes2D              :: Axes2D
    , divisions           :: Int
    , lineCharacteristics :: [Characteristic]
    , faceCharacteristics :: [Characteristic]
    , labelColor          :: Color
    , labelSize           :: Double
    }
  | BoxGrid
    {
      gridAlias           :: GridAlias
    , axes3D              :: Axes3D
    , divisions           :: Int
    , lineCharacteristics :: [Characteristic]
    , faceCharacteristics :: [Characteristic]
    , labelColor          :: Color
    , labelSize           :: Double
    }
    deriving (Eq, Generic, Read, Show)

instance FromJSON Grid

instance ToJSON Grid


type GriddedLocation = (GridAlias, Location)


data Extent =
    Extent1D
    {
      origin  :: Location
    , cornerX :: Location
    }
  | Extent2D
    {
      origin  :: Location
    , cornerX :: Location
    , cornerY :: Location
    }
  | Extent3D
    {
      origin  :: Location
    , cornerX :: Location
    , cornerY :: Location
    , cornerZ :: Location
    }
    deriving (Eq, Generic, Read, Show)

instance FromJSON Extent

instance ToJSON Extent


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
    deriving (Eq, Generic, Read, Show)

instance FromJSON Container

instance ToJSON Container
    

type LinkAlias = String


data Link =
    Point
    {
      linkAlias       :: LinkAlias
    , linkedGrid      :: GridAlias
    , characteristics :: [Characteristic]
    }
  | Polyline
    {
      linkAlias       :: LinkAlias
    , linkedGrids     :: [GridAlias]
    , characteristics :: [Characteristic]
    }
    deriving (Eq, Generic, Read, Show)

instance FromJSON Link

instance ToJSON Link


data Characteristic =
    ColorSet
    {
      normalColor     :: Color
    , selectColor     :: Color
    , highlightColor  :: Color
    }
    deriving (Eq, Generic, Read, Show)

instance FromJSON Characteristic

instance ToJSON Characteristic


data Presentation =
  Presentation
  {
    containers    :: [Container]
  , links         :: [Link]
  , animation     :: Maybe VariableAlias -- FIXME: Needs implementation.
  , selectorColor :: Color               -- FIXME: Needs implementation.
  , selectorSize  :: Double              -- FIXME: Needs implementation.
  }
    deriving (Eq, Generic, Read, Show)

instance FromJSON Presentation

instance ToJSON Presentation


data WorldExtent =
  WorldExtent
  {
    worldOrigin  :: Location
  , worldCornerX :: Location
  , worldCornerY :: Location
  , worldCornerZ :: Location
  }
    deriving (Eq, Generic, Read, Show)

instance FromJSON WorldExtent

instance ToJSON WorldExtent


data World =
  World
  {
    displayExtent :: WorldExtent
  , worldExtent   :: WorldExtent
  , baseSize      :: Double      -- FIXME: Needs implementation.
  }
    deriving (Eq, Generic, Read, Show)

instance FromJSON World

instance ToJSON World