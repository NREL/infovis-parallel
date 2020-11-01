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

  var right = [3]float32{1, 0, 0}
//var back  = [3]float32{0, 0, 1}
  var noRotation = [4]float32{0, 0, 0, 1}

  var mesh int8
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
      mesh = model.MESH_LINE
      for _, positions := range positionss {
        for i := 1; i < len(positions); i++ {
          u0 := positions[i - 1]
          u1 := positions[i]
          ud := scaleAndAdd(u1, u0, -1)
          uc := scaleAndAdd(u0, ud, 0.5)
          r := rotationFromVectorPair(right, ud)
          s := [3]float32{length(ud), float32(geometry.Size), float32(geometry.Size)}
          inode := builder.MakeNode(mesh, uc, r, s, color, text)
          nodes = append(nodes, inode)
        }
      }

  }

  return nodes

}


/*
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
