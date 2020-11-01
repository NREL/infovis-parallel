package export


import (
  "bitbucket.org/bwbush/infovis-parallel/go/infovis/protobuf"
)


type managerType struct {
  Frames map[int32]*frameType
}

func makeManager() managerType {
  return managerType{make(map[int32]*frameType)}
}

func (manager *managerType) insert(geometries []*protobuf.Geometry) {
  for _, geometry := range geometries {
    manager.insert1(geometry)
  }
}

func (manager *managerType) insert1(geometry *protobuf.Geometry) {
  var fram = geometry.Fram
  if  _, ok := manager.Frames[fram]; !ok {
    manager.Frames[fram] = makeFrame()
  }
  manager.Frames[fram].insert(geometry)
}

func (manager *managerType) deletE(idens []int64) {
  for _, frame := range manager.Frames {
    frame.deletE(idens)
  }
}


type frameType struct {
  Displays map[int32]*displayType
}

func makeFrame() *frameType {
  var frame = frameType{make(map[int32]*displayType)}
  for _, mesh := range meshes {
    frame.Displays[mesh] = makeDisplay()
  }
  return &frame
}

func (frame *frameType) insert(geometry *protobuf.Geometry) {
  for mesh, display := range frame.Displays {
    display.insert(mesh, geometry)
  }
}

func (frame *frameType) deletE(idens []int64) {
  for _, display := range frame.Displays {
    display.deletE(idens)
  }
}


type displayType struct {
  Geometries map[int64]*protobuf.Geometry
}

func makeDisplay() *displayType {
  return &displayType{make(map[int64]*protobuf.Geometry)}
}

func (display *displayType) insert(mesh int32, delta *protobuf.Geometry) {
  var mesh1 = findShapeMesh(delta)
  var iden = delta.Iden
  if geometry, ok := display.Geometries[iden]; ok {
    if mesh1 == 0 || mesh1 == mesh {
      merge(geometry, delta)
    }
  } else if mesh1 == mesh {
    display.Geometries[iden] = delta
  } // FIXME: Handle glyph change.
}

func (display *displayType) deletE(idens []int64) {
  for _, iden := range idens {
    delete(display.Geometries, iden)
  }
}


func findShapeMesh(geometry *protobuf.Geometry) int32 {
  switch geometry.Type {
    case geometryPoints:
      if deltaGlyph(geometry) {
        switch geometry.Glyp {
          case glyphCube:
            return cubeMesh
          case glyphSphere:
            return sphereMesh
          default:
        }
      }
      return -1
    case geometryPolylines:
      return polylineMesh
    case geometryRectangles:
      return rectangleMesh
    case geometryLabel:
      return labelMesh
    case geometryAxis:
      return axisMesh
    default:
      return 0
  }
}
