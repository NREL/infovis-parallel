package model


const (
  GLYPH_CUBE   = iota
  GLYPH_SPHERE = iota
)

const (
  GLYPH_BOX      = iota
  GLYPH_CYLINDER = iota
)

const (
  MASK_POSN =  1
  MASK_SIZE =  2
  MASK_COLR =  4
  MASK_TEXT =  8
  MASK_GLYP = 16
)

const (
  GEOMETRY_POINTS     = 1 + iota
  GEOMETRY_POLYLINES  = 1 + iota
  GEOMETRY_RECTANGLES = 1 + iota
  GEOMETRY_LABEL      = 1 + iota
  GEOMETRY_AXIS       = 1 + iota
)


const (
  MESH_CUBE   = iota
  MESH_SPHERE = iota
  MESH_LINE   = iota
  MESH_SQUARE = iota
  MESH_LABEL  = iota
  MESH_ARROW  = iota
)

var MESHES = [...]int32{MESH_CUBE, MESH_SPHERE, MESH_LINE, MESH_SQUARE, MESH_LABEL, MESH_ARROW}


func deltaPosition(geometry *Geometry) bool {
  return geometry.Mask & MASK_POSN != 0
}

func deltaSize(geometry *Geometry) bool {
  return geometry.Mask & MASK_SIZE != 0
}

func deltaColor(geometry *Geometry) bool {
  return geometry.Mask & MASK_COLR != 0
}

func deltaText(geometry *Geometry) bool {
  return geometry.Mask & MASK_TEXT != 0
}

func deltaGlyph(geometry *Geometry) bool {
  return geometry.Mask & MASK_GLYP != 0
}


func merge(geometry *Geometry, delta *Geometry) {
  if deltaPosition(delta) {
    geometry.Cnts = delta.Cnts
    geometry.Posx = delta.Posx
    geometry.Posy = delta.Posy
    geometry.Posz = delta.Posz
  }
  if deltaSize(delta) {
    geometry.Size = delta.Size
  }
  if deltaColor(delta) {
    geometry.Colr = delta.Colr
  }
  if deltaText(delta) {
    geometry.Text = delta.Text
  }
  if deltaGlyph(delta) {
    geometry.Glyp = delta.Glyp
  }
}


/*
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
*/
