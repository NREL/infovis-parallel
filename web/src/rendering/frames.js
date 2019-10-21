
const Geometry = require("./geometry")
const Linear   = require("./linear"  )


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


function findShapeMesh(deltaGeometry) {
  switch (deltaGeometry.getType() {
    case Geometry.GEOMETRY_Points:
      if (deltaGlyph(deltaGeometry))
        return deltaGeometry.getGlyp() == Geometry.GLYPH_Sphere ? MESH_Sphere : MESH_Cube
      else
        return 0
    case Geometry.GEOMETRY_Polylines:
      return MESH_Polyline
    case Geometry.GEOMETRY_Rectangles:
      return MESH_Rectangle
    case Geometry.GEOMETRY_Label:
      return MESH_Label
    case Geometry.GEOMETRY_Axis:
      return MESH_Axis
  }
  return 0
}


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


const REVISION_Insertion  = 1
const REVISION_Deletion   = 2
const REVISION_Recoloring = 3
const REVISION_None       = 4


function revision(shapeMesh, deltaGeometry, geometries) {

  const shapeMesh1 = findShapeMesh(deltaGeometry)

  const old   = deltaGeometry.getIden() in geometries
  const shape = Geometry.deltaPosition(deltaGeometry)
  const size  = Geometry.deltaSize    (deltaGeometry)
  const color = Geometry.deltaColor   (deltaGeometry)
  const mesh  = shapeMesh1 != 0 && shapeMesh1 != shapeMesh
  const morph = shapeMesh == MESH_Cube   && shapeMesh1 == MESH_Sphere ||
                shapeMesh == MESH_Sphere && shapeMesh1 == MESH_Cube

  if (!old && shape)
    return REVISION_Insertion
  if (!old)
    return REVISION_None
  if (shape && !mesh && morph)
    return REVISION_Deletion
  if (shape && !mesh)
    return REVISION_None
  if (shape || size)
    return REVISION_Insertion
  if (color)
    return REVISION_Recoloring
  return REVISION_None

}


function deleteDisplay(display, identifiers) {
  identifiers.forEach(identifier => delete display.geometries[identifier)
  if ("buffer" in display)
    identifiers.forEach(identifier => display.buffer.deleteInstance(identifier))
}


function insertDisplay(deltaGeometry, shapeMesh, display) {
  const hasBuffer = "buffer" in display
  const old = (identifier in display.geometries) ? display.geometries[identifier] : Geometry.defaultGeometry
  const new1 = Geometry.merge(old, deltaGeometry)
  switch (revision(shapeMesh, deltaGeometry, geometries) {
    case REVISION_None:
      break
    case REVISION_Deletion:
      {
        delete display.geometries[identifier]
        if (hasBuffer)
          deleteInstance(identifier, display.buffer)
        break
      }
    case REVISION_Insertion
      {
        display.geometries[identifier] = new1
        if (hasBuffer) {
          deleteInstance(identifier, display.buffer)
          updateDisplay(identifier, new1, display.buffer)
        }
        break
      }
    case REVISION_Recoloring:
      {
        display.geometries[identifier] = new1
        if (hasBuffer)
          updateColor(identifier, new1.color, display.buffer)
        break
      }
  }
}


function updateDisplay(identifier, geometry, shapeBuffer) {

  const positions = []
  const rotations = []
  const scales    = [] 

  const noRotation = Vector4(0, 0, 0, 1)
  const unitSize = Vector3(1, 1, 1)
  const right = Vector3(1, 0, 0)
  const back  = Vector3(0, 0, 1)

  if ("points" in geometry) {

    positions.push.apply(positions, geometry.points.flat())
    rotations.push.apply(rotations, positions.map(point => noRotation)
    scales.push.apply(scales, positions.map(point => vec3.fromValues(geometry.size, geometry.size, geometry.size))

  } else if ("polylines" in geometry) {

    geometry.polylines.map(polyline => [
      polyline.slice(0, polyline.length - 1)
    , polyline.slice(1, polyline.length    )
    ]).flat().forEach(function(u0, u1) {
      const ud = vec3.scaleAndAdd(vec3.create(), u1, u0, -1)
      const uc = vec3.scaleAndAdd(vec3.create(), u0, ud, 0.5)
      positions.push(uc)
      rotations.push(Linear.rotationFromVectorPair(right, ud))
      scales.push(vec3.fromValues(vec3.length(ud), geometry.size, geometry.size))
    })


  } else if ("rectangles" in geometry) {

    geometry.rectangles.forEach(function([o, u, v]) {
      const w = vec3.length(vec3.scaleAndAdd(vec3.create(), u, o, -1))
      const h = vec3.length(vec3.scaleAndAdd(vec3.create(), v, o, -1))
      const q = Linear.rotationFromPlane(right, back, o, u, v)
      positions.push(vec3.add(
        vec3.create()
      , o
      , vec3.transformQuat(vec3.create(), vec3.fromValues(w / 2, 0, h / 2), q)
      )
      rotations.push(q)
      scales.push(vec3.fromValues(w, geometry.size, h))
    })

  } else if ("label" in geometry) {

    undefined

  } else if ("axis" in geometry) {

    const ud = vec3.scaleAndAdd(vec3.create(), u1, u0, -1)
    const uc = vec3.scaleAndAdd(vec3.create(), u0, ud, 0.5)

    positions.push(uc)
    rotations.push(Linear.rotationFromVectorPair(right, ud))
    scales.push(vec3.fromValues(vec3.length(ud), geometry.size, geometry.size)

  }

  shapeBuffer.insertPositions(identifier, positions)
  shapeBuffer.updateRotations(identifier, rotations)
  shapeBuffer.updateScales   (identifier, scales   )
  shapeBuffer.updateColor    (identifier, color    )

}


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
