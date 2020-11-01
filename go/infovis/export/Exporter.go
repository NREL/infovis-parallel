package export


import (
  "io/ioutil"
  "github.com/qmuntal/gltf"
  "github.com/golang/glog"
  "github.com/golang/protobuf/proto"
  "bitbucket.org/bwbush/infovis-parallel/go/infovis/model"
)


func Export(filenames []string) {

  var manager = model.MakeManager()

  for _, filename := range filenames {
    if buffer, err := ioutil.ReadFile(filename); err != nil {
      glog.Errorf("Reading file %s encountered %v.\n", filename, err)
    } else {
      request := model.Request{}
      if err = proto.Unmarshal(buffer, &request); err != nil {
        glog.Errorf("Could not unmarshal %s: %v.\n", filename, err)
      } else {
        manager.Insert(request.Upsert)
      }
    }
  }

  doc := gltf.NewDocument()
  builder := MakeBuilder(doc)

  for _, frame := range manager.Frames {
    for _, display := range frame.Displays {
      for _, geometry := range display.Geometries {
        nodes := builder.Render(geometry)
        doc.Scenes[0].Nodes = append(doc.Scenes[0].Nodes, nodes...)
      }
    }
  }

/*
  doc.Scenes[0].Nodes = []uint32{
    builder.MakeNode(
      model.MESH_CUBE,
      [3]float32{ 0,  0,  0},
      [4]float32{0, 0, 0, 1},
      [3]float32{10, 10, 10},
      [4]float32{1.0, 0.0, 0.0, 1.0},
      "Cube",
    ),
    builder.MakeNode(
      model.MESH_SPHERE,
      [3]float32{20,  0,  0},
      [4]float32{0, 0, 0, 1},
      [3]float32{10, 10, 10},
      [4]float32{0.0, 1.0, 0.0, 0.9},
      "Icosahedron",
    ),
    builder.MakeNode(
      model.MESH_LINE,
      [3]float32{ 0,  0, 20},
      [4]float32{0, 0, 0, 1},
      [3]float32{40, 10, 10},
      [4]float32{0.0, 0.0, 1.0, 0.8},
      "Tube",
    ),
    builder.MakeNode(
      model.MESH_SQUARE,
      [3]float32{ 0, 20,  0},
      [4]float32{0, 0, 0, 1},
      [3]float32{10, 10, 10},
      [4]float32{1.0, 0.0, 0.0, 1.0},
      "Square",
    ),
    builder.MakeNode(
      model.MESH_ARROW,
      [3]float32{ 0, 20, 20},
      [4]float32{0, 0, 0, 1},
      [3]float32{40, 10, 10},
      [4]float32{0.0, 1.0, 0.0, 0.9},
      "Arrow",
    ),
  }
*/

  if err := gltf.SaveBinary(doc, "./example.glb"); err != nil {
    panic(err)
  }

}
