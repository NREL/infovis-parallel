package model


const (
  GLYPH_CUBE   int32 = iota
  GLYPH_SPHERE       = iota
)

const (
  GLYPH_BOX      int32 = iota
  GLYPH_CYLINDER       = iota
)

const (
  MASK_POSN int32 = 1 << iota
  MASK_SIZE       = 1 << iota
  MASK_COLR       = 1 << iota
  MASK_TEXT       = 1 << iota
  MASK_GLYP       = 1 << iota
)

const (
  GEOMETRY_POINTS     int32 = 1 + iota
  GEOMETRY_POLYLINES        = 1 + iota
  GEOMETRY_RECTANGLES       = 1 + iota
  GEOMETRY_LABEL            = 1 + iota
  GEOMETRY_AXIS             = 1 + iota
)


const (
  MESH_CUBE   int8 = iota
  MESH_SPHERE      = iota
  MESH_LINE        = iota
  MESH_SQUARE      = iota
  MESH_LABEL       = iota
  MESH_ARROW       = iota
)

var MESHES = [...]int8{MESH_CUBE, MESH_SPHERE, MESH_LINE, MESH_SQUARE, MESH_LABEL, MESH_ARROW}


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
