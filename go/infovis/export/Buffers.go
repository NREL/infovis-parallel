package export


import (
  "github.com/qmuntal/gltf"
  "bitbucket.org/bwbush/infovis-parallel/go/infovis/model"
)


type Buffers = map[int32]*Buffer

func MakeBuffers(doc *gltf.Document) (Buffers, colorsType) {
  var buffers = make(Buffers)
  var colors = make(colorsType)
  buffers[model.MESH_CUBE  ] = MakeBuffer(doc, &colors, "cube"       , Cube       (doc, 1           ))
  buffers[model.MESH_SPHERE] = MakeBuffer(doc, &colors, "icosahedron", Icosahedron(doc, 1           ))
  buffers[model.MESH_LINE  ] = MakeBuffer(doc, &colors, "tube"       , Tube       (doc, 1, 1        ))
  buffers[model.MESH_SQUARE] = MakeBuffer(doc, &colors, "square"     , Square     (doc, 1           ))
  buffers[model.MESH_ARROW ] = MakeBuffer(doc, &colors, "arrow"      , Arrow      (doc, 1, 1, 0.1, 2))
  return buffers, colors
}


type Buffer struct {
  MakeMesh func(*gltf.Document, [4]float32) *gltf.Mesh
  Meshes   map[color]*gltf.Mesh
}

func MakeBuffer(doc *gltf.Document, colors *colorsType, name string, accessors [2]uint32) *Buffer {
  return &Buffer{
    MakeMesh: func(doc *gltf.Document, rgba [4]float32) *gltf.Mesh {
                return &gltf.Mesh{
                  Name: name,
                  Primitives: []*gltf.Primitive{{
                    Indices: gltf.Index(accessors[1]),
                    Attributes: map[string]uint32{
                      "POSITION": accessors[0],
                    },
                    Material: colorMaterial(doc, colors, rgba),
                  }},
                }
              },
    Meshes  : make(map[color]*gltf.Mesh),
  }
}


type color struct {
  r int
  g int
  b int
  a int
}

const colorPrecision = 10

func makeColor(rgba [4]float32) color {
  return color{
    int(colorPrecision * rgba[0]),
    int(colorPrecision * rgba[1]),
    int(colorPrecision * rgba[2]),
    int(colorPrecision * rgba[3]),
  }
}

type colorsType = map[color]uint32

func colorMaterial(doc *gltf.Document, colors *colorsType, rgba [4]float32) *uint32 {
  c := makeColor(rgba)
  if _, ok := (*colors)[c]; !ok {
    material := gltf.Material{
      AlphaMode: gltf.AlphaBlend,
      PBRMetallicRoughness: &gltf.PBRMetallicRoughness{
        BaseColorFactor: &[4]float32{rgba[0], rgba[1], rgba[2], rgba[3], },
        MetallicFactor : gltf.Float(0.75),
        RoughnessFactor: gltf.Float(0.50),
      },
    }
    i := uint32(len(doc.Materials))
    doc.Materials = append(doc.Materials, &material)
    (*colors)[c] = i
  }
  return gltf.Index((*colors)[c])
}
