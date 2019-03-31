{-# LANGUAGE DeriveAnyClass  #-}
{-# LANGUAGE DeriveGeneric   #-}
{-# LANGUAGE RecordWildCards #-}


module InfoVis.Parallel.Presenter.Link (
  LinkDisplay
, LinkAlias
, Link(..)
, linker
, link
) where


import Data.Aeson.Types (FromJSON(..), ToJSON(..))
import Data.Binary (Binary)
import Data.Maybe (fromJust)
import GHC.Generics (Generic)
import InfoVis.Parallel.Presenter.Grid (GridAlias, Styling(..))
import InfoVis.Parallel.Types (Geometry(..), Glyph(..), Position, Shape(..))


type LinkDisplay = [(LinkAlias, Geometry)]


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


linker :: [(GridAlias, Position)]
       -> Link
       -> (LinkAlias, Geometry)
linker positions Point{..} =
  (
    linkAlias
  , Geometry
    {
      shape = Points Sphere [[fromJust $ linkedGrid `lookup` positions]]
    , size  = 0.01
    , color = normalColor styling
    , text  = ""
    }
  )
linker positions Polyline{..} =
  (
    linkAlias
  , Geometry
    {
      shape = Polylines [[fromJust $ linkedGrid `lookup` positions | linkedGrid <- linkedGrids]]
    , size  = 0.01
    , color = normalColor styling
    , text  = ""
    }
  )


link :: [Link]
     -> [(GridAlias, Position)]
     -> [(LinkAlias, Geometry)]
link links positions = linker positions <$> links
