package model


type Manager struct {
  Frames map[int32]*Frame
}

func MakeManager() Manager {
  return Manager{make(map[int32]*Frame)}
}

func (manager *Manager) Insert(geometries []*Geometry) {
  for _, geometry := range geometries {
    manager.Insert1(geometry)
  }
}

func (manager *Manager) Insert1(geometry *Geometry) {
  var fram = geometry.Fram
  if  _, ok := manager.Frames[fram]; !ok {
    manager.Frames[fram] = MakeFrame()
  }
  manager.Frames[fram].Insert(geometry)
}

func (manager *Manager) DeletE(idens []int64) {
  for _, frame := range manager.Frames {
    frame.Delete(idens)
  }
}


type Frame struct {
  Displays map[int8]*Display
}

func MakeFrame() *Frame {
  var frame = Frame{make(map[int8]*Display)}
  for _, mesh := range MESHES {
    frame.Displays[mesh] = MakeDisplay()
  }
  return &frame
}

func (frame *Frame) Insert(geometry *Geometry) {
  for mesh, display := range frame.Displays {
    display.Insert(mesh, geometry)
  }
}

func (frame *Frame) Delete(idens []int64) {
  for _, display := range frame.Displays {
    display.Delete(idens)
  }
}


type Display struct {
  Geometries map[int64]*Geometry
}

func MakeDisplay() *Display {
  return &Display{make(map[int64]*Geometry)}
}

func (display *Display) Insert(mesh int8, delta *Geometry) {
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

func (display *Display) Delete(idens []int64) {
  for _, iden := range idens {
    delete(display.Geometries, iden)
  }
}


func findShapeMesh(geometry *Geometry) int8 {
  switch geometry.Type {
    case GEOMETRY_POINTS:
      if deltaGlyph(geometry) {
        switch geometry.Glyp {
          case GLYPH_CUBE:
            return MESH_CUBE
          case GLYPH_SPHERE:
            return MESH_SPHERE
          default:
            return 0
        }
      }
      return -1
    case GEOMETRY_POLYLINES:
      return MESH_LINE
    case GEOMETRY_RECTANGLES:
      return MESH_SQUARE
    case GEOMETRY_LABEL:
      return MESH_TEXT
    case GEOMETRY_AXIS:
      return MESH_ARROW
    default:
      return 0
  }
}
