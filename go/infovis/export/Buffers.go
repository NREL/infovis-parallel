package export


import (
  "github.com/qmuntal/gltf"
  "bitbucket.org/bwbush/infovis-parallel/go/infovis/model"
)


type Builder struct {
  doc     *gltf.Document
  buffers map[int8]*Buffer
  colors  colors
}

func MakeBuilder(doc *gltf.Document) *Builder {
  var builder = Builder{doc, make(map[int8]*Buffer), make(colors)}
  builder.buffers[model.MESH_CUBE  ] = makeBuffer(&builder.colors, "cube"       , Cube       (doc, 1           ))
  builder.buffers[model.MESH_SPHERE] = makeBuffer(&builder.colors, "icosahedron", Icosahedron(doc, 1           ))
  builder.buffers[model.MESH_LINE  ] = makeBuffer(&builder.colors, "tube"       , Tube       (doc, 1, 1        ))
  builder.buffers[model.MESH_SQUARE] = makeBuffer(&builder.colors, "square"     , Square     (doc, 1           ))
  builder.buffers[model.MESH_ARROW ] = makeBuffer(&builder.colors, "arrow"      , Arrow      (doc, 1, 1, 0.1, 2))
  return &builder
}

func (builder *Builder) MakeMesh(mesh int8, rgba [4]float32) uint32 {
  return builder.buffers[mesh].MakeMesh(builder.doc, rgba)
}

func (builder *Builder) MakeNode(
  mesh        int8      ,
  translation [3]float32,
  rotation    [4]float32,
  scale       [3]float32,
  color       [4]float32,
  name        string    ,
) uint32 {
  var node = gltf.Node{
    Mesh       : gltf.Index(builder.MakeMesh(mesh, color)),
    Translation: translation                              ,
    Rotation   : rotation                                 ,
    Scale      : scale                                    ,
  }
  if name != "" {
    node.Name = name
  }
  inode := uint32(len(builder.doc.Nodes))
  builder.doc.Nodes = append(builder.doc.Nodes, &node)
  return inode
}


type Buffer struct {
  makeMesh func(*gltf.Document, color, [4]float32) *gltf.Mesh
  meshes   map[color]uint32
}

func makeBuffer(colors *colors, name string, accessors [2]uint32) *Buffer {
  return &Buffer{
    makeMesh: func(doc *gltf.Document, c color, rgba [4]float32) *gltf.Mesh {
                return &gltf.Mesh{
                  Name: name,
                  Primitives: []*gltf.Primitive{{
                    Indices: gltf.Index(accessors[1]),
                    Attributes: map[string]uint32{
                      "POSITION": accessors[0],
                    },
                    Material: colorMaterial(doc, colors, c, rgba),
                  }},
                }
              },
    meshes  : make(map[color]uint32),
  }
}

func (buffer *Buffer) MakeMesh(doc *gltf.Document, rgba [4]float32) uint32 {
  c := makeColor(rgba)
  if imesh, ok := buffer.meshes[c]; ok {
    return imesh
  } else {
    mesh := buffer.makeMesh(doc, c, rgba)
    imesh = uint32(len(doc.Meshes))
    doc.Meshes = append(doc.Meshes, mesh)
    buffer.meshes[c] = imesh
    return imesh
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

type colors = map[color]uint32

func colorMaterial(doc *gltf.Document, colors *colors, c color, rgba [4]float32) *uint32 {
  if _, ok := (*colors)[c]; !ok {
    material := gltf.Material{
      AlphaMode: gltf.AlphaBlend,
      PBRMetallicRoughness: &gltf.PBRMetallicRoughness{
        BaseColorFactor: &rgba,
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
