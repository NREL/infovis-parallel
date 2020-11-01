package export


import (
  "bitbucket.org/bwbush/infovis-parallel/go/infovis/protobuf"
)


const (
  glyphCube   = iota
  glyphSphere = iota
)

const (
  glyphBox      = iota
  glyphCylinder = iota
)

const (
  maskPosn =  1
  maskSize =  2
  maskColr =  4
  maskText =  8
  maskGlyp = 16
)

const (
  geometryPoints     = 1 + iota
  geometryPolylines  = 1 + iota
  geometryRectangles = 1 + iota
  geometryLabel      = 1 + iota
  geometryAxis       = 1 + iota
)


func deltaPosition(geometry *protobuf.Geometry) bool {
  return geometry.Mask & maskPosn != 0
}

func deltaSize(geometry *protobuf.Geometry) bool {
  return geometry.Mask & maskSize != 0
}

func deltaColor(geometry *protobuf.Geometry) bool {
  return geometry.Mask & maskColr != 0
}

func deltaText(geometry *protobuf.Geometry) bool {
  return geometry.Mask & maskText != 0
}

func deltaGlyph(geometry *protobuf.Geometry) bool {
  return geometry.Mask & maskGlyp != 0
}


func merge(geometry *protobuf.Geometry, delta *protobuf.Geometry) {
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
