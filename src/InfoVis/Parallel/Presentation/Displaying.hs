{-# LANGUAGE RecordWildCards #-}


module InfoVis.Parallel.Presentation.Displaying (
  prepareGrids
, prepareLinks
) where


import Data.Function.MapReduce (groupReduceByKey)
import InfoVis.Parallel.Presentation.Presenting (linkPresentation, presentWorld)
import InfoVis.Parallel.Presentation.Scaling (scaleToWorld)
import InfoVis.Parallel.Rendering.Types (DisplayItem(..), DisplayList(..), DisplayText(..), DisplayType(..), fromLocations)
import InfoVis.Parallel.Types (Location)
import InfoVis.Parallel.Types.Dataset (Dataset(..), Record, RecordIdentifier, Variable(..))
import InfoVis.Parallel.Types.Presentation (Characteristic, GridAlias, LinkAlias, Presentation)
import InfoVis.Parallel.Types.World (World)


prepareGrids :: World -> Presentation -> Dataset -> ([DisplayList (DisplayType, GridAlias) Int], [DisplayText String Location])
prepareGrids world presentation Dataset{..} =
  let
    (grids, texts) = presentWorld world presentation
  in
    (
      prepare GridType grids
    , [
        text {textContent = n}
      |
        text@DisplayText{..} <- texts
      , let Just n = textContent `lookup` [(variableAlias, variableName) | ContinuousVariable{..} <- variables]
      ]
    )


prepareLinks :: World -> Presentation -> Dataset -> [Record] -> [DisplayList (DisplayType, LinkAlias) RecordIdentifier]
prepareLinks world presentation dataset rs =
  prepare LinkType
    . concat 
    . zipWith (linkPresentation presentation) [0..]
    $ scaleToWorld world presentation dataset
    <$> rs


prepare :: Ord a => DisplayType -> [DisplayItem (a, (b, [Characteristic])) Location] -> [DisplayList (DisplayType, a) b]
prepare dt =
  groupReduceByKey
    (
      \DisplayItem{..} -> (fst itemIdentifier, itemPrimitive)
    )
    (
      \(n, listPrimitive) dis ->
        let
          listIdentifier = (dt, n)
          listCharacteristics = snd . snd . itemIdentifier $ head dis
          listVertexIdentifiers = concatMap (\DisplayItem{..} -> length itemVertices `replicate` fst (snd itemIdentifier)) dis
          listVertices = concatMap itemVertices dis
        in
          DisplayList{..}
    )
    . fromLocations