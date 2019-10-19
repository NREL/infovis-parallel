
function listFrames(manager) {
  return Object.keys(manager.frames)
}


function createManager(gl) {
  return {
    program : prepareShapeProgram(gl)
  , frames  : {}
  , current : 0
  }
}


function destroyManager(gl, manager) {
  // FIXME: Destroy the shape program.
  Object.values(manager.frames).forEach(frame => destroyFrame(gl, frame))
}


function reset(manager) {
  Object.values(manager.frames).forEach(resetFrame)  
}


function insert(deltaGeometries, manager) {
  deltaGeometries.forEach(deltaGeometry => insert1(manager, deltaGeometry))
}


function insert1(manager, geometry) {
  if (Object.keys(manager.frames).length == 0)
    manager.currentFrame = geometry.frame
  if (!(frame in manager.frames))
    manager.frames[frame] = createFrame(manager.program)
  insertFrame(manager.frames[frame], geometry)
}


function delete0(identifiers, manager) {
  Object.values(manager.frames).forEach(frame => deleteFrame(identifier, frame))
}  


function prepare(gl, manager) {
  Object.values(manager.frames).forEach(frame => prepareFrame(gl, frame))
}


function draw(gl, manager) {
  if (manager.current in manager.frames)
    drawFrame(gl, manager.frames[manager.current])
}


const MESH_Cube      = 1
const MESH_Sphere    = 2
const MESH_Polyline  = 3
const MESH_Rectangle = 4
const MESH_Label     = 5
const MESH_Axis      = 6


function mesh(shapeMesh) {
  switch (shapeMesh) {
    case MESH_Cube:
      return cube(1)
    case MESH_Sphere:
      return icosahedron(1)
    case MESH_Polyline:
      return tube(1, 1)
    case MESH_Rectangle:
      return square(1)
    case MESH_Label:
      return undefined
    case MESH_Axis:
      return arrow(1, 1, 0.1, 2)
  }
}


findShapeMesh :: Shape
              -> ShapeMesh
findShapeMesh shape =
  case shape of
    Points     Cube   _ -> CubeMesh
    Points     Sphere _ -> SphereMesh
    Polylines         _ -> PolylineMesh
    Rectangles        _ -> RectangleMesh
    Label             _ -> LabelMesh
    Axis              _ -> AxisMesh


function createFrame(shapeProgram) {
  var frame = {}
  [
    MESH_Cube
  , MESH_Sphere
  , MESH_Polyline
  , MESH_Rectangle
  , MESH_Label
  , MESH_Axis
  ].forEach(shapeMesh => frame[shapeMesh] = createDisplay(program, shapeMesh))
  return frame
}


function destroyFrame(gl, frame) {
  Object.values(frame).forEach(display => destroyDisplay(gl, display))
}


function resetFrame(frame) {
  Object.values(frame).forEach(resetDisplay)
}


function insertFrame(frame, deltaGeometry) {
  Object.entries(frame).forEach(([shapeMesh, display]) => insertDisplay(deltaGeometry, shapeMesh, display))
}


function deleteFrame(frame, identifiers) {
  Object.values(frame).forEach(display => deleteDisplay(display, identifier))
}


function prepareFrame(gl, frame) {
  Object.values(frame).forEach(display => prepareDisplay(gl, display)
}


function drawFrame(gl, frame) {
  Object.values(frame).forEach(display => drawDisplay(gl, display))
}


function resetDisplay(display) {
  deleteDisplay(display, Object.keys(display.geometries))
}


function createDisplay(shapeProgram, shapeMesh) {
  var display = {
    labelDisplay : shapeMesh == MESH_Label
  , geometries   : {}
  ]
  if (!display.labelDisplay)
    display.buffer = createShapeBuffer(program, mesh(shapeMesh))
  return display
}


function destoryDisplay(gl, display) {
  if ("buffer" in display)
    destroyShapeBuffer(gl, display.buffer)
}


function prepareDisplay(gl, display) {
  if ("buffer" in display)
    prepareShapeBuffer(gl, display.buffer)
}


function drawDisplay(gl, display) {
  if ("buffer" in display)
    drawInstances(gl, display.buffer)
  else
    ; // FIXME: Daw labels.
}


merge :: Geometry
      -> DeltaGeometry
      -> Geometry
merge Geometry{..} DeltaGeometry{..} =
  Geometry
  {
    shape = case (deltaShape, deltaGlyph) of
              (Just (Points _ pps), Just g') -> Points g' pps
              (Just shape'        , _      ) -> shape'
              _                              -> shape
  , size  = fromMaybe size  deltaSize
  , color = fromMaybe color deltaColor
  , text  = fromMaybe text  deltaText
  }


const REVISION_Insertion  = 1
const REVISION_Deletion   = 2
const REVISION_Recoloring = 3
const REVISION_None       = 4


revision :: ShapeMesh
         -> DeltaGeometry
         -> M.Map Identifier Geometry
         -> Revision
revision shapeMesh DeltaGeometry{..} geometries' =
  let
    old = identifier `M.lookup` geometries'
    Just shapeMesh' = findShapeMesh <$> deltaShape
    CubeMesh   `morph` SphereMesh = True
    SphereMesh `morph` CubeMesh   = True
    _          `morph` _          = False
  in
    case (old, deltaShape, deltaSize, deltaColor, shapeMesh == shapeMesh', shapeMesh `morph` shapeMesh') of
      (Nothing, Just _, _     , _     , True , _    ) -> Insertion
      (Nothing, _     , _     , _     , _    , _    ) -> None
      (_      , Just _, _     , _     , False, True ) -> Deletion
      (_      , Just _, _     , _     , False, _    ) -> None
      (_      , Just _, _     , _     , _    , _    ) -> Insertion
      (_      , _     , Just _, _     , _    , _    ) -> Insertion
      (_      , _     , _     , Just _, _    , _    ) -> Recoloring
      (_      , _     , _     , _     , _    , _    ) -> None


function deleteDisplay(display, identifiers) {
  
deleteDisplay :: Display
              -> [Identifier]
              -> Display
deleteDisplay display@LabelDisplay{..} identifiers =
  display
    & over geometriesLens
      (flip (foldl (flip M.delete)) identifiers)
deleteDisplay display@ShapeDisplay{..} identifiers =
  display
    & over geometriesLens
      (flip (foldl (flip M.delete)) identifiers)
    & over bufferLens
      (flip (foldl deleteInstance) identifiers)


insertDisplay :: DeltaGeometry
              -> ShapeMesh
              -> Display
              -> Display
insertDisplay deltaGeometry@DeltaGeometry{..} shapeMesh display@LabelDisplay{..} =
  let
    old = M.findWithDefault def identifier geometries
    new = old `merge` deltaGeometry
  in
    case revision shapeMesh deltaGeometry geometries of
      None      -> display
      Deletion  -> display
                     & over geometriesLens (M.delete identifier)
      _         -> display
                     & over geometriesLens (M.insert identifier new)
insertDisplay deltaGeometry@DeltaGeometry{..} shapeMesh display@ShapeDisplay{..} =
  let
    old = M.findWithDefault def identifier geometries
    new = old `merge` deltaGeometry
  in
    case revision shapeMesh deltaGeometry geometries of
      None      -> display
      Deletion  -> display
                     & over geometriesLens (M.delete identifier)
                     & over bufferLens     (`deleteInstance` identifier)
      Insertion -> display
                     & over geometriesLens (M.insert identifier new)
                     & over bufferLens     (updateDisplay (identifier, new) . flip deleteInstance identifier)
      Recoloring-> display
                     & over geometriesLens (M.insert identifier new)
                     & over bufferLens     (updateColor (identifier, color new))
    

updateDisplay :: (Identifier, Geometry)
              -> ShapeBuffer
              -> ShapeBuffer
updateDisplay (identifier, Geometry{..}) =
  let
    noRotation = Quaternion 1 $ V3 0 0 0
    right = V3 1 0 0
    back = V3 0 0 1
    toPosition (P (V3 x y z)) = realToFrac <$> Vertex3 x y z
    toRotation (Quaternion w (V3 x y z)) = realToFrac <$> Vector4 x y z w
    toScale (V3 x y z) = realToFrac <$> Vector3 x y z
    (positions, rotations, scales) =
      unzip3 $ case shape of
        Points _   pss -> let
                            make p = (p, noRotation, V3 size size size)
                          in
                            make <$> concat pss
        Polylines  pps -> let
                            make u0 u1 =
                              let
                                ud = u1 .-. u0
                                uc = u0 .+^ ud / 2
                              in
                                (
                                  uc
                                , rotationFromVectorPair right ud
                                , V3 (norm ud) size size
                                )
                          in
                            zipWith make (concatMap init pps) (concatMap tail pps)
        Rectangles pps -> let
                            make (o, u, v) =
                              let
                                w = norm $ u .-. o
                                h = norm $ v .-. o
                                q = rotationFromPlane right back o u v
                              in
                                (
                                  o .+^ q `rotate` V3 (w / 2) 0 (h / 2)
                                , q
                                , V3 w size h
                                )
                          in
                            make <$> pps
        Label      _   -> undefined
        Axis  (u0, u1) -> let
                            ud = u1 .-. u0
                            uc = u0 .+^ ud / 2
                          in
                            [(
                              uc
                            , rotationFromVectorPair right ud
                            , V3 (norm ud) size size
                            )]
  in
      updateColor     (identifier,                color    )
    . updateScales    (identifier, toScale    <$> scales   )
    . updateRotations (identifier, toRotation <$> rotations)
    . insertPositions (identifier, toPosition <$> positions)


module.exports = {
  program        : program
, createManager  : createManager
, destroyManager : destroyManager
, currentFrame   : currentFrame
, listFrames     : listFrames
, insert         : insert
, delete0        : delete0
, reset          : reset
, prepare        : prepare
, draw           : draw
}
