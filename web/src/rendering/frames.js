
'use strict';


const Buffers  = require("./buffers" )
const Geometry = require("./geometry")
const Linear   = require("./linear"  )
const Program  = require("./program" )
const Shapes   = require("./shapes"  )
const Text     = require("./text"    )

require("../gl-matrix")


const DEBUG = true


const mat4 = glMatrix.mat4
const quat = glMatrix.quat
const vec3 = glMatrix.vec3


function listFrames(manager) {
  return manager.frames.keys()
}


function createManager(gl) {
  return {
    program    : Program.prepareShapeProgram(gl)
  , frames     : new Map()
  , current    : 0
  , projection : mat4.create()
  , modelView  : mat4.create()
  }
}


function destroyManager(gl, manager) {
  // FIXME: Destroy the shape program.
  manager.frames.forEach((frame, _) => destroyFrame(gl, frame))
}


function reset(manager) {
  manager.frames.forEach((frame, _) => resetFrame(frame))
}


function insert(gl, deltaGeometries, manager) {
  deltaGeometries.forEach((deltaGeometry) => insert1(gl, manager, deltaGeometry))
}


function insert1(gl, manager, deltaGeometry) {
  const frame = deltaGeometry.getFram()
  if (manager.frames.size == 0)
    manager.current = frame
  if (!manager.frames.has(frame))
    manager.frames.set(frame, createFrame(gl, manager.program))
  insertFrame(manager.frames.get(frame), deltaGeometry)
}


function delete0(identifiers, manager) {
  manager.frames.forEach((frame, _) => deleteFrame(identifiers, frame))
}


function prepare(gl, manager) {
  manager.frames.forEach((frame, f) => {if (DEBUG) console.debug("prepare: frame =", f); prepareFrame(gl, frame)})
}


function draw(gl, manager) {
  if (manager.frames.has(manager.current)) {
    if (DEBUG) console.debug("draw: frame =", manager.current)
    drawFrame(gl, manager.frames.get(manager.current), manager.projection, manager.modelView)
  }
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
  const frame = new Map()
  meshes.forEach((shapeMesh) => frame.set(shapeMesh, createDisplay(gl, shapeProgram, shapeMesh)))
  return frame
}


function destroyFrame(gl, frame) {
  frame.forEach((display, _) => destroyDisplay(gl, display))
}


function resetFrame(frame) {
  frame.forEach((display, _) => resetDisplay(display))
}


function insertFrame(frame, deltaGeometry) {
  frame.forEach((display, shapeMesh) => insertDisplay(deltaGeometry, shapeMesh, display))
}


function deleteFrame(frame, identifiers) {
  frame.forEach((display, _) => deleteDisplay(display, identifiers))
}


function prepareFrame(gl, frame) {
  frame.forEach((display, mesh) => {if (DEBUG) console.debug("prepareFrame: mesh =", mesh); prepareDisplay(gl, display)})
}


function drawFrame(gl, frame, projection, modelView) {
  frame.forEach((display, mesh) => {if (DEBUG) console.debug("drawFrame: mesh =", mesh); drawDisplay(gl, display, projection, modelView)})
}


function resetDisplay(display) {
  deleteDisplay(display, display.geometries.keys())
}


function createDisplay(gl, shapeProgram, shapeMesh) {
  const display = {
    geometries : new Map()
  }
  if (shapeMesh == MESH_Label)
    display.labels = new Map()
  else
    display.buffer = Buffers.createShapeBuffer(gl, shapeProgram, gl.TRIANGLES, mesh(shapeMesh))
  return display
}


function destroyDisplay(gl, display) {
  if (hasBuffer(display))
    Buffers.destroyShapeBuffer(gl, display.buffer)
}


function prepareDisplay(gl, display) {
  if (hasBuffer(display))
    Buffers.prepareShapeBuffer(gl, display.buffer)
}


function drawDisplay(gl, display, projection, modelView) {
  if (hasBuffer(display))
    Buffers.drawInstances(gl, display.buffer, projection, modelView)
  if (hasPixmaps(display))
    Text.drawText()
}


function hasBuffer(display) {
  return "buffer" in display
}


function hasPixmaps(display) {
  return "pixmaps" in display
}


const REVISION_Insertion  = 1
const REVISION_Deletion   = 2
const REVISION_Recoloring = 3
const REVISION_None       = 4


function revision(shapeMesh, deltaGeometry, geometries) {

  const shapeMesh1 = findShapeMesh(deltaGeometry)

  const mesh     = shapeMesh1 == shapeMesh
  const relevant = mesh || shapeMesh1 == 0
  const old      = geometries.has(deltaGeometry.getIden())
  const position = Geometry.deltaPosition(deltaGeometry)
  const size     = Geometry.deltaSize    (deltaGeometry)
  const color    = Geometry.deltaColor   (deltaGeometry)
  const morph    = shapeMesh == MESH_Cube   && shapeMesh1 == MESH_Sphere ||
                   shapeMesh == MESH_Sphere && shapeMesh1 == MESH_Cube

  //  FIXME: Recheck this logic.
  if (!old && relevant) return REVISION_Insertion  // New and relevant.
  if (!old)             return REVISION_None       // New and irrelevant.
  if (!mesh && morph)   return REVISION_Deletion   // Changed to different mesh, and no longer relevant.
  if (!relevant)        return REVISION_None       // Old, but irrelevant.
  if (position || size) return REVISION_Insertion  // Relevant change in position or size.
  if (color)            return REVISION_Recoloring // Relevant change in color.
  return REVISION_None                             // Nothing to do.

}


function deleteDisplay(display, identifiers) {
  identifiers.forEach((identifier) => display.geometries.delete(identifier))
  if (hasBuffer(display))
    identifiers.forEach((identifier) => Buffers.deleteInstance(display.buffer, identifier))
}


function insertDisplay(deltaGeometry, shapeMesh, display) {
  const hasBuffer1 = hasBuffer(display)
  const identifier = deltaGeometry.getIden()
  const geometry = display.geometries.has(identifier) ? display.geometries.get(identifier) : Geometry.defaultGeometry()
  const revision1 = revision(shapeMesh, deltaGeometry, display.geometries)
  if (revision1 != REVISION_None)
    Geometry.merge(geometry, deltaGeometry)
  switch (revision1) {
    case REVISION_None:
      break
    case REVISION_Deletion:
      {
        display.geometries.delete(identifier)
        if (hasBuffer1)
          Buffers.deleteInstance(display.buffer, identifier)
        break
      }
    case REVISION_Insertion:
      {
        display.geometries.set(identifier, geometry)
        if (hasBuffer1) {
          Buffers.deleteInstance(display.buffer, identifier)
          updateDisplay(identifier, geometry, display.buffer)
        }
        if (hasPixmaps(display))
          display.pixmaps.set(identifier, Text.makePixmaps(geometry.text))
        break
      }
    case REVISION_Recoloring:
      {
        display.geometries.set(identifier, geometry)
        if (hasBuffer1)
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

  if (Geometry.hasPoints(geometry)) {

    positions.push(...geometry.shape.points.flat())
    rotations.push(...positions.map((point) => noRotation))
    scales.push(...positions.map((point) => vec3.fromValues(geometry.size, geometry.size, geometry.size)))

  } else if (Geometry.hasPolylines(geometry)) {

    geometry.shape.polylines.map((polyline) => [
      polyline.slice(0, polyline.length - 1)
    , polyline.slice(1, polyline.length    )
    ]).forEach(([u0s, u1s]) =>
      u0s.map(function(u0, i) {
        const u1 = u1s[i]
        const ud = vec3.scaleAndAdd(vec3.create(), u1, u0, -1)
        const uc = vec3.scaleAndAdd(vec3.create(), u0, ud, 0.5)
        positions.push(uc)
        rotations.push(Linear.rotationFromVectorPair(right, ud))
        scales.push(vec3.fromValues(vec3.length(ud), geometry.size, geometry.size))
      })
    )


  } else if (Geometry.hasRectangles(geometry)) {

    geometry.shape.rectangles.forEach(function([o, u, v]) {
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

  } else if (Geometry.hasLabel(geometry)) {

    undefined

  } else if (Geometry.hasAxis(geometry)) {

    const u0 = geometry.shape.axis[0]
    const u1 = geometry.shape.axis[1]
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
, delete         : delete0
, reset          : reset
, prepare        : prepare
, draw           : draw
}
