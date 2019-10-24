
const Buffers  = require("./buffers" )
const Geometry = require("./geometry")
const Linear   = require("./linear"  )
const Program  = require("./program" )
const Shapes   = require("./shapes"  )

require("../gl-matrix")


const quat = glMatrix.quat
const vec3 = glMatrix.vec3


function listFrames(manager) {
  return Object.keys(manager.frames)
}


function createManager(gl) {
  return {
    program : Program.prepareShapeProgram(gl)
  , frames  : {}
  , current : 0
  }
}


function destroyManager(gl, manager) {
  // FIXME: Destroy the shape program.
  Object.values(manager.frames).forEach((frame) => destroyFrame(gl, frame))
}


function reset(manager) {
  Object.values(manager.frames).forEach(resetFrame)
}


function insert(gl, deltaGeometries, manager) {
  deltaGeometries.forEach((deltaGeometry) => insert1(gl, manager, deltaGeometry))
}


function insert1(gl, manager, geometry) {
  const frame = geometry.frame
  if (Object.keys(manager.frames).length == 0)
    manager.currentFrame = frame
  if (!(frame in manager.frames))
    manager.frames[frame] = createFrame(gl, manager.program)
  insertFrame(manager.frames[frame], geometry)
}


function delete0(identifiers, manager) {
  Object.values(manager.frames).forEach((frame) => deleteFrame(identifiers, frame))
}


function prepare(gl, manager) {
  Object.values(manager.frames).forEach((frame) => prepareFrame(gl, frame))
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

const meshes =[MESH_Cube, MESH_Sphere, MESH_Polyline, MESH_Rectangle, MESH_Label, MESH_Axis]


function mesh(shapeMesh) {
  switch (shapeMesh) {
    case MESH_Cube:
      return Shapes.cube(1)
    case MESH_Sphere:
      return Shapes.icosahedron(1)
    case MESH_Polyline:
      return Shapes.tube(1, 1)
    case MESH_Rectangle:
      return Shapes.square(1)
    case MESH_Label:
      return undefined
    case MESH_Axis:
      return Shapes.arrow(1, 1, 0.1, 2)
  }
}


function findShapeMesh(deltaGeometry) {
  switch (deltaGeometry.getType()) {
    case Geometry.GEOMETRY_Points:
      if (Geometry.deltaGlyph(deltaGeometry))
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


function createFrame(gl, shapeProgram) {
  const frame = {}
  meshes.forEach((shapeMesh) => frame[shapeMesh] = createDisplay(gl, shapeProgram, shapeMesh))
  return frame
}


function destroyFrame(gl, frame) {
  Object.values(frame).forEach((display) => destroyDisplay(gl, display))
}


function resetFrame(frame) {
  Object.values(frame).forEach(resetDisplay)
}


function insertFrame(frame, deltaGeometry) {
  Object.entries(frame).forEach(([shapeMesh, display]) => insertDisplay(deltaGeometry, shapeMesh, display))
}


function deleteFrame(frame, identifiers) {
  Object.values(frame).forEach((display) => deleteDisplay(display, identifiers))
}


function prepareFrame(gl, frame) {
  Object.values(frame).forEach((display) => prepareDisplay(gl, display))
}


function drawFrame(gl, frame) {
  Object.values(frame).forEach((display) => drawDisplay(gl, display))
}


function resetDisplay(display) {
  deleteDisplay(display, Object.keys(display.geometries))
}


function createDisplay(gl, shapeProgram, shapeMesh) {
  const display = {
    geometries   : {}
  }
  if (shapeMesh != MESH_Label)
    display.buffer = Buffers.createShapeBuffer(gl, shapeProgram, gl.TRIANGLES, mesh(shapeMesh))
  return display
}


function destroyDisplay(gl, display) {
  if ("buffer" in display)
    Buffers.destroyShapeBuffer(gl, display.buffer)
}


function prepareDisplay(gl, display) {
  if ("buffer" in display)
    Buffers.prepareShapeBuffer(gl, display.buffer)
}


function drawDisplay(gl, display) {
  if ("buffer" in display)
    Buffers.drawInstances(gl, display.buffer)
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
  identifiers.forEach((identifier) => delete display.geometries[identifier])
  if ("buffer" in display)
    identifiers.forEach((identifier) => Buffers.deleteInstance(display.buffer, identifier))
}


function insertDisplay(deltaGeometry, shapeMesh, display) {
  const hasBuffer = "buffer" in display
  const identifier = deltaGeometry.getIden()
  const geometry = (identifier in display.geometries) ? display.geometries[identifier] : Geometry.defaultGeometry()
  Geometry.merge(geometry, deltaGeometry)
  switch (revision(shapeMesh, deltaGeometry, display.geometries)) {
    case REVISION_None:
      break
    case REVISION_Deletion:
      {
        delete display.geometries[identifier]
        if (hasBuffer)
          Buffers.deleteInstance(display.buffer, identifier)
        break
      }
    case REVISION_Insertion:
      {
        display.geometries[identifier] = geometry
        if (hasBuffer) {
          Buffers.deleteInstance(display.buffer, identifier)
          updateDisplay(identifier, geometry, display.buffer)
        }
        break
      }
    case REVISION_Recoloring:
      {
        display.geometries[identifier] = geometry
        if (hasBuffer)
          Buffers.updateColor(identifier, geometry.color, display.buffer)
        break
      }
  }
}


function updateDisplay(identifier, geometry, shapeBuffer) {

  const positions = []
  const rotations = []
  const scales    = []
  const color     = geometry.color

  const noRotation = quat.fromValues(0, 0, 0, 1)
  const right = vec3.fromValues(1, 0, 0)
  const back  = vec3.fromValues(0, 0, 1)

  if ("points" in geometry) {

    positions.push(...geometry.points.flat())
    rotations.push(...positions.map((point) => noRotation))
    scales.push(...positions.map((point) => vec3.fromValues(geometry.size, geometry.size, geometry.size)))

  } else if ("polylines" in geometry) {

    geometry.polylines.map((polyline) => [
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
      ))
      rotations.push(q)
      scales.push(vec3.fromValues(w, geometry.size, h))
    })

  } else if ("label" in geometry) {

    undefined

  } else if ("axis" in geometry) {

    const u0 = geometry.axis[0]
    const u1 = geometry.axis[1]
    const ud = vec3.scaleAndAdd(vec3.create(), u1, u0, -1)
    const uc = vec3.scaleAndAdd(vec3.create(), u0, ud, 0.5)

    positions.push(uc)
    rotations.push(Linear.rotationFromVectorPair(right, ud))
    scales.push(vec3.fromValues(vec3.length(ud), geometry.size, geometry.size))

  }

  Buffers.insertPositions(identifier, positions, shapeBuffer)
  Buffers.updateRotations(identifier, rotations, shapeBuffer)
  Buffers.updateScales   (identifier, scales   , shapeBuffer)
  Buffers.updateColor    (identifier, color    , shapeBuffer)

}


module.exports = {
  createManager  : createManager
, destroyManager : destroyManager
, currentFrame   : (manager) => manager.current
, listFrames     : listFrames
, insert         : insert
, delete0        : delete0
, reset          : reset
, prepare        : prepare
, draw           : draw
}
