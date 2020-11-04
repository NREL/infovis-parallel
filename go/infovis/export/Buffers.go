package export


import (
  "bytes"
  "image"
  clr "image/color"
  "image/draw"
  "image/png"
  "io/ioutil"
  "golang.org/x/image/font"
  "golang.org/x/image/math/fixed"
  "github.com/golang/freetype/truetype"
  "github.com/golang/glog"
  "github.com/qmuntal/gltf"
  "github.com/qmuntal/gltf/modeler"
  "bitbucket.org/bwbush/infovis-parallel/go/infovis/model"
)


type Builder struct {
  doc           *gltf.Document
  buffers       map[int8]*Buffer
  colors        colors
  face          font.Face
  imageIndices  uint32
  imagePosition uint32
  imageCoords   uint32
  imageSampler  uint32
}


func MakeBuilder(doc *gltf.Document, fontfile string) *Builder {
  var builder = Builder{
    doc,
    make(map[int8]*Buffer),
    make(colors), makeFace(fontfile),
    modeler.WriteIndices(doc, []uint8{0,1,2, 0,2,3, 0,3,2, 0,2,1}),
    modeler.WritePosition(doc, [][3]float32{{0,0,0}, {1,0,0}, {1,1,0}, {0,1,0}}),
    modeler.WriteTextureCoord(doc, [][2]float32{{0,1}, {1,1}, {1,0}, {0,0}}),
    uint32(len(doc.Samplers)),
  }
  builder.buffers[model.MESH_CUBE  ] = makeBuffer(&builder.colors, "cube"       , Cube       (doc, 1           ))
  builder.buffers[model.MESH_SPHERE] = makeBuffer(&builder.colors, "icosahedron", Icosahedron(doc, 1           ))
  builder.buffers[model.MESH_LINE  ] = makeBuffer(&builder.colors, "tube"       , Tube       (doc, 1, 1        ))
  builder.buffers[model.MESH_SQUARE] = makeBuffer(&builder.colors, "square"     , Square     (doc, 1           ))
  builder.buffers[model.MESH_ARROW ] = makeBuffer(&builder.colors, "arrow"      , Arrow      (doc, 1, 1, 0.1, 2))
  doc.Samplers = []*gltf.Sampler{{WrapS: gltf.WrapRepeat, WrapT: gltf.WrapRepeat}}
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
    Name       : name                                     ,
    Mesh       : gltf.Index(builder.MakeMesh(mesh, color)),
    Translation: translation                              ,
    Rotation   : rotation                                 ,
    Scale      : scale                                    ,
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

const colorPrecision = 50

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


const fontSize float64 = 12

const fontDpi float64 = 300

func makeFace(fontfile string) font.Face {
  fontBytes, err := ioutil.ReadFile(fontfile)
  if err != nil {
    glog.Fatalf("Failed reading font file %s: %v\n", fontfile, err)
  }
  fontData, err := truetype.Parse(fontBytes)
  if err != nil {
    glog.Fatalf("Failed parsing font file %s: %v\n", fontfile, err)
  }
  return truetype.NewFace(fontData, &truetype.Options{
      Size:    fontSize,
      DPI:     fontDpi,
      Hinting: font.HintingFull,
    })
}

func (builder *Builder) rasterize(text string, foreground uint32) (int, int, []byte) {

  face := builder.face

  w := font.MeasureString(face, text).Ceil()
  h := face.Metrics().Height.Ceil()
  rgba := image.NewRGBA(image.Rect(0, 0, w, h))
  draw.Draw(rgba, rgba.Bounds(), image.Transparent, image.ZP, draw.Src)

  fg := image.NewUniform(clr.RGBA{
    uint8(foreground & 0xFF000000 >> 24),
    uint8(foreground & 0x00FF0000 >> 16),
    uint8(foreground & 0x0000FF00 >>  8),
    uint8(foreground & 0x000000FF      ),
  })

  drawer := &font.Drawer{Dst: rgba, Src: fg, Face: face,}
  drawer.Dot = fixed.Point26_6{X: 0, Y: face.Metrics().Ascent - face.Metrics().Descent,}
  drawer.DrawString(text)

  buffer := bytes.NewBuffer([]byte{})
  if err := png.Encode(buffer, rgba); err != nil {
    glog.Fatalf("Failed writing raster buffer: %v.\n", err)
  }

  return w, h, buffer.Bytes()

}

func (builder *Builder) makeImage(
  buffer      []byte    ,
  translation [3]float32,
  rotation    [4]float32,
  scale       [3]float32,
  name        string    ,
) uint32 {

  doc := builder.doc

  r := bytes.NewReader(buffer)
  iimage := uint32(len(doc.Images))
  modeler.WriteImage(builder.doc, name, "image/png", r)

  itexture := uint32(len(doc.Textures))
  texture := gltf.Texture{
    Sampler: gltf.Index(builder.imageSampler),
    Source: gltf.Index(iimage),
  }
  doc.Textures = append(doc.Textures, &texture)

  imaterial := uint32(len(doc.Materials))
  material := gltf.Material{
      AlphaMode: gltf.AlphaBlend,
      PBRMetallicRoughness: &gltf.PBRMetallicRoughness{
        BaseColorTexture: &gltf.TextureInfo{Index: itexture,},
        MetallicFactor : gltf.Float(0),
        RoughnessFactor: gltf.Float(1),
      },
    }
  doc.Materials = append(doc.Materials, &material)

  imesh := uint32(len(doc.Meshes))
  mesh := gltf.Mesh{
    Primitives: []*gltf.Primitive{{
      Indices: gltf.Index(builder.imageIndices),
      Attributes: map[string]uint32{
        "POSITION"  : builder.imagePosition,
        "TEXCOORD_0": builder.imageCoords,
      },
      Material: gltf.Index(imaterial),
    }},
  }
  doc.Meshes = append(doc.Meshes, &mesh)

  inode := uint32(len(doc.Nodes))
  node := gltf.Node{
    Name       : name             ,
    Mesh       : gltf.Index(imesh),
    Translation: translation      ,
    Rotation   : rotation         ,
    Scale      : scale            ,
  }
  doc.Nodes = append(doc.Nodes, &node)

  return inode

}
