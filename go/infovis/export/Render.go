package export


import (
  "bitbucket.org/bwbush/infovis-parallel/go/infovis/model"
)


func decodeColor(rgba uint32) [4]float32 {
  return [4]float32{
    float32(rgba & 0xFF000000) / 0xFF000000,
    float32(rgba & 0x00FF0000) / 0x00FF0000,
    float32(rgba & 0x0000FF00) / 0x0000FF00,
    float32(rgba & 0x000000FF) / 0x000000FF,
  }
}


func (builder *Builder) Render(geometry *model.Geometry) []uint32 {

  var nodes = []uint32{}
  if geometry.Size <= 0 || geometry.Colr & 0x000000FF == 00 {
    return nodes
  }

  var right = [3]float32{1, 0, 0}
  var up    = [3]float32{0, 1, 0}
  var back  = [3]float32{0, 0, 1}
  var noRotation = [4]float32{0, 0, 0, 1}

  var color = decodeColor(geometry.Colr)
  var text = geometry.Text

  var positionss = [][][3]float32{}
  var n = 0
  for _, cnt := range geometry.Cnts {
    positions := make([][3]float32, cnt)
    for i := 0; i < int(cnt); i++ {
      positions[i] = [3]float32{
        float32(geometry.Posx[n]),
        float32(geometry.Posy[n]),
        float32(geometry.Posz[n]),
      }
      n++
    }
    positionss = append(positionss, positions)
  }

  switch geometry.Type {

    case model.GEOMETRY_POINTS:
      var mesh int8
      switch geometry.Glyp {
        case model.GLYPH_CUBE:
          mesh = model.MESH_CUBE
        case model.GLYPH_SPHERE:
          mesh = model.MESH_SPHERE
      }
      scale := [3]float32{float32(geometry.Size), float32(geometry.Size), float32(geometry.Size)}
      for _, positions := range positionss {
        for _, position := range positions {
          inode := builder.MakeNode(mesh, position, noRotation, scale, color, text)
          nodes = append(nodes, inode)
        }
      }

    case model.GEOMETRY_POLYLINES:
      for _, positions := range positionss {
        for i := 1; i < len(positions); i++ {
          u0 := positions[i - 1]
          u1 := positions[i]
          ud := scaleAndAdd(u1, u0, -1)
          uc := scaleAndAdd(u0, ud, 0.5)
          q := rotationFromVectorPair(right, ud)
          s := [3]float32{length(ud), float32(geometry.Size), float32(geometry.Size)}
          inode := builder.MakeNode(model.MESH_LINE, uc, q, s, color, text)
          nodes = append(nodes, inode)
        }
      }

    case model.GEOMETRY_RECTANGLES:
      for _, positions := range positionss {
        o := positions[0]
        u := positions[1]
        v := positions[2]
        w := length(scaleAndAdd(u, o, -1))
        h := length(scaleAndAdd(v, o, -1))
        q := rotationFromPlane(right, back, o, u, v)
        p := add(o, transformQuat([3]float32{w / 2, 0, h / 2}, q))
        s := [3]float32{w, float32(geometry.Size), h}
        inode := builder.MakeNode(model.MESH_LINE, p, q, s, color, text)
        nodes = append(nodes, inode)
      }

    case model.GEOMETRY_LABEL:

      for _, positions := range positionss {
        w, h, img := builder.rasterize(geometry.Text, geometry.Colr)
        p := positions[0]
        u := positions[1]
        v := positions[2]
        q := rotationFromPlane(right, up, p, u, v)
        s := scale([3]float32{float32(w) / float32(h), 1, 1}, float32(geometry.Size))
        inode := builder.makeImage(img, p, q, s, geometry.Text)
        nodes = append(nodes, inode)
      }

    case model.GEOMETRY_AXIS:
      for _, positions := range positionss {
        u0 := positions[0]
        u1 := positions[1]
        ud := scaleAndAdd(u1, u0, -1)
        uc := scaleAndAdd(u0, ud, 0.5)
        q := rotationFromVectorPair(right, ud)
        s := [3]float32{length(ud), float32(geometry.Size), float32(geometry.Size)}
        inode := builder.MakeNode(model.MESH_ARROW, uc, q, s, color, text)
        nodes = append(nodes, inode)
      }


  }

  return nodes

}
