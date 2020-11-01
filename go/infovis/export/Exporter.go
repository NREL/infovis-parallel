package export


import (
  "fmt"
  "io/ioutil"
  "path/filepath"
  "github.com/qmuntal/gltf"
  "github.com/golang/glog"
  "github.com/golang/protobuf/proto"
  "bitbucket.org/bwbush/infovis-parallel/go/infovis/model"
)


func Export(filenames []string) {

  var manager = model.MakeManager()

  for _, filename := range filenames {
    matches, err := filepath.Glob(filename)
    if err != nil {
      glog.Warningf("Invalid glob pattern '%s': %v.\n", filename, err)
      continue
    }
    if len(matches) == 0 {
      glog.Warningf("Glob pattern '%s' matched no files.\n", filename)
    }
    for _, match := range matches {
      if buffer, err := ioutil.ReadFile(match); err != nil {
        glog.Errorf("Reading file %s encountered %v.\n", match, err)
      } else {
        request := model.Request{}
        if err = proto.Unmarshal(buffer, &request); err != nil {
          glog.Errorf("Could not unmarshal %s: %v.\n", match, err)
        } else {
          manager.Insert(request.Upsert)
        }
      }
    }
  }

  doc := gltf.NewDocument()
  builder := MakeBuilder(doc)

  allNodes := []uint32{}
  for iframe, frame := range manager.Frames {
    for idisplay, display := range frame.Displays {
      for igeometry, geometry := range display.Geometries {
        fmt.Printf("Frame %4d, Display %d, Geometry %8d\r", iframe, idisplay, igeometry)
        nodes := builder.Render(geometry)
        allNodes = append(allNodes, nodes...)
      }
    }
  }
  fmt.Printf("                                             \r")

  root := gltf.Node{
    Name: "root",
    Scale: [3]float32{2, 2, 2},
    Children: allNodes,
  }
  iroot := uint32(len(doc.Nodes))
  doc.Nodes = append(doc.Nodes, &root)
  doc.Scenes[0].Nodes = append(doc.Scenes[0].Nodes, iroot)

  fmt.Printf("Materials: %d\n", len(doc.Materials))
  fmt.Printf("Meshes:    %d\n", len(doc.Meshes))
  fmt.Printf("Nodes:     %d\n", len(doc.Nodes))

  if err := gltf.SaveBinary(doc, "./example.glb"); err != nil {
    panic(err)
  }

}
