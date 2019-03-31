{-# LANGUAGE DeriveAnyClass  #-}
{-# LANGUAGE DeriveGeneric   #-}
{-# LANGUAGE RecordWildCards #-}


module InfoVis.Parallel.Presenter.Grid (
  Presentable(..)
, GridIdentifier
, GridDisplay
, GridAlias
, Grid(..)
) where


import Control.Lens.Getter ((^.))
import Data.Aeson.Types (FromJSON(..), ToJSON(..))
import Data.Binary (Binary)
import Data.Default (def)
import GHC.Generics (Generic)
import InfoVis.Parallel.Types (Color, Geometry(..), Shape(Polylines, Rectangles, Label))
import InfoVis.Parallel.Presenter.Types (Axis(..), Axes1D, Axes2D, Axes3D, Projectable(..), Styling(..))
import Linear.Affine (Point(..), (.+^), (.-^))
import Linear.V1 (R1(..))
import Linear.V2 (R2(..))
import Linear.V3 (R3(..), V3(..))
import Linear.Vector ((*^), basis, zero)


class Presentable a where
  present :: a -> GridDisplay


ex, ey, ez :: V3 Double
[ex, ey, ez] = basis


type GridIdentifier = (GridAlias, Int)


type GridDisplay = [(GridIdentifier, Geometry)]


type GridAlias = String


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


instance Projectable Grid where
  project LineGrid{..}      = project axes1D
  project RectangleGrid{..} = project axes2D
  project BoxGrid{..}       = project axes3D


instance Presentable Grid where

  present LineGrid{..} =
    let
      axes =
        [
          axis (axes1D ^. _x) zero ex ey labelColor labelSize
        ]
      deltaX = ex / (1 + fromIntegral divisions)
      edges =
        arrayed divisions deltaX (makeLine lineStyling deltaX) zero
    in
      number gridAlias $ axes ++ edges
  
  present RectangleGrid{..} =
    let
      axes =
        [
          axis (axes2D ^. _x) zero ex ey labelColor labelSize
        , axis (axes2D ^. _y) zero ey ex labelColor labelSize
        ]
      deltaX = ex / (1 + fromIntegral divisions)
      deltaY = ex / (1 + fromIntegral divisions)
      faces =
        arrayed divisions deltaX
          (
            arrayed divisions deltaY
              $ makeRectangle faceStyling deltaX deltaY
          ) zero
      edges = 
           set deltaX deltaY
        ++ set deltaY deltaX
          where
            set u v =
              arrayed (divisions + 1) u
                (
                  arrayed divisions v
                    $ makeLine lineStyling v
                ) zero
    in
      number gridAlias $ axes ++ faces ++ edges
  
  present BoxGrid{..} =
    let
      axes =
        [
          axis (axes3D ^. _x) zero ex ((ey + ez) / sqrt 2) labelColor labelSize
        , axis (axes3D ^. _y) zero ey ((ez + ex) / sqrt 2) labelColor labelSize
        , axis (axes3D ^. _z) zero ey ((ex + ey) / sqrt 2) labelColor labelSize
        ]
      deltaX = ex / (1 + fromIntegral divisions)
      deltaY = ex / (1 + fromIntegral divisions)
      deltaZ = ex / (1 + fromIntegral divisions)
      faces =
           set deltaX deltaY deltaZ
        ++ set deltaY deltaZ deltaX
        ++ set deltaZ deltaX deltaY
          where
            set u v w =
              arrayed (divisions + 1) u
                (
                  arrayed divisions v
                    (
                      arrayed divisions w
                        $ makeRectangle faceStyling v w
                    )
                ) zero
      edges = 
           set deltaX deltaY deltaZ
        ++ set deltaY deltaZ deltaX
        ++ set deltaZ deltaX deltaY
          where
            set u v w =
              arrayed (divisions + 1) u
                (
                  arrayed (divisions + 1) v
                    (
                      arrayed divisions w
                        $ makeLine lineStyling w
                    )
                ) zero
    in
      number gridAlias $ axes ++ faces ++ edges


number :: GridAlias
       -> [Geometry]
       -> GridDisplay
number alias elements =
  [
    ((alias, n), element)
  |
    (n, element) <- zip[1..] elements
  ]


arrayed :: Int
        -> V3 Double
        -> (Point V3 Double -> [Geometry])
        -> Point V3 Double
        -> [Geometry]
arrayed divisions deltaX f origin =
  concatMap
    (f . (origin .+^) . (*^ deltaX) . fromIntegral)
    [0..divisions]


makeLine :: Styling
         -> V3 Double
         -> Point V3 Double
         -> [Geometry]
makeLine Styling{..} deltaX origin =
  [
    def
    {
      shape = Polylines [[origin, origin .+^ deltaX]]
    , color = normalColor
    , size  = thickness
    }
  ]


makeRectangle :: Styling
              -> V3 Double
              -> V3 Double
              -> Point V3 Double
              -> [Geometry]
makeRectangle Styling{..} deltaX deltaY origin =
  [
    def
    {
      shape = Rectangles [(origin, origin .+^ deltaX, origin .+^ deltaY)]
    , color = normalColor
    , size  = thickness
    }
  ]


axis :: Axis
     -> Point V3 Double
     -> V3 Double
     -> V3 Double
     -> Color
     -> Double
     -> Geometry
axis Axis{..} origin deltaX deltaY color' size' =
  def
  {
    shape = Label (origin, origin .+^ deltaX, origin .-^ size' *^ deltaY)
  , color = color'
  , size  = size'
  , text  = axisVariable
  }
