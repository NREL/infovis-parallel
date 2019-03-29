{-# LANGUAGE DeriveAnyClass  #-}
{-# LANGUAGE DeriveGeneric   #-}
{-# LANGUAGE RecordWildCards #-}


module InfoVis.Parallel.Presenter.Grid (
  GridIdentifier
, GridDisplay
, GridAlias
, Grid(..)
, presentGrid
) where


import Control.Lens.Getter ((^.))
import Data.Aeson.Types (FromJSON(..), ToJSON(..))
import Data.Binary (Binary)
import Data.Default (def)
import GHC.Generics (Generic)
import InfoVis.Parallel.Types (Color, Geometry(..), Shape(Points, Polylines, Rectangles, Label))
import InfoVis.Parallel.Presenter.Types (Axis(..), Axes1D, Axes2D, Axes3D, Styling(..))
import Linear.Affine (Point(..), (.+^), (.-^))
import Linear.V1 (R1(..), V1(..))
import Linear.V2 (R2(..), V2(..))
import Linear.V3 (R3(..), V3(..))
import Linear.Vector ((^+^), (*^), (^*), basis, zero)


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


presentGrid :: Grid
            -> GridDisplay

presentGrid LineGrid{..} =
  let
    axes =
      [
        axis (axes1D ^. _x) zero ex ey labelColor labelSize
      ]
    edges =
      segments divisions zero ex normalColor 0.005
        where Styling{..} = lineStyling
  in
    number gridAlias $ axes ++ edges

presentGrid RectangleGrid{..} =
  let
    axes =
      [
        axis (axes2D ^. _x) zero ex ey labelColor labelSize
      , axis (axes2D ^. _y) zero ey ex labelColor labelSize
      ]
    faces =
      rectangles divisions zero ex ey normalColor 0.005
         where Styling{..} = faceStyling
    edges = 
      segments2 divisions zero ex ey normalColor 0.005
        where Styling{..} = lineStyling
  in
    number gridAlias $ axes ++ faces ++ edges

presentGrid BoxGrid{..} =
  let
    axes =
      [
        axis (axes3D ^. _x) zero ex ey labelColor labelSize
      , axis (axes3D ^. _y) zero ey ex labelColor labelSize
      , axis (axes3D ^. _z) zero ey ex labelColor labelSize
      ]
    faces = undefined
    edges = undefined
  in
    undefined -- number gridAlias $ axes ++ faces ++ concat edges


number :: GridAlias
       -> [Geometry]
       -> GridDisplay
number alias elements =
  [
    ((alias, n), element)
  |
    (n, element) <- zip[1..] elements
  ]


segments :: Int
         -> Point V3 Double
         -> V3 Double
         -> Color
         -> Double
         -> [Geometry]
segments divisions origin deltaX color' size' =
  [
    def
      {
        shape = Polylines
                  [[
                    origin .+^  i      *^ deltaX'
                  , origin .+^ (i + 1) *^ deltaX'
                  ]]
      , color = color'
      , size  = size'
      }
  |
    i <- fromIntegral <$> [0..divisions]
  , let deltaX' = deltaX / (1 + fromIntegral divisions)
  ]


segments2 :: Int -- FIXME: Repeat with offset.
          -> Point V3 Double
          -> V3 Double
          -> V3 Double
          -> Color
          -> Double
          -> [Geometry]
segments2 divisions origin deltaX deltaY color' size' =
  concat
    [
      segments divisions (origin .+^ i *^ deltaX') deltaY color' size'
    |
      let deltaX' = deltaX / (1 + fromIntegral divisions)
    , i <- fromIntegral <$> [0..divisions]
    ]


rectangles :: Int
           -> Point V3 Double
           -> V3 Double
           -> V3 Double
           -> Color
           -> Double
           -> [Geometry]
rectangles divisions origin deltaX deltaY color' size' =
  [
    def
    {
      shape = Rectangles
                [(
                  origin .+^  i      *^ deltaX' .+^  j      *^ deltaY'
                , origin .+^ (i + 1) *^ deltaX' .+^  j      *^ deltaY'
                , origin .+^  i      *^ deltaX' .+^ (j + 1) *^ deltaY'
                )]
    , color = color'
    , size  = size'
    }
  |
    i <- fromIntegral <$> [0..divisions]
  , j <- fromIntegral <$> [0..divisions]
  , let deltaX' = deltaX / (1 + fromIntegral divisions)
        deltaY' = deltaY / (1 + fromIntegral divisions)
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
    shape = Label
              (
                origin
              , origin .+^ deltaX
              , origin .-^ size' *^ deltaY
              )
  , color = color'
  , text  = axisVariable
  }
