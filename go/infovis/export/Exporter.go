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


func Export(innames []string, outname string, useScenes bool) {

  var manager = model.MakeManager()

  for _, filename := range innames {
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
    sceneNodes := []uint32{}
    for idisplay, display := range frame.Displays {
      for igeometry, geometry := range display.Geometries {
        fmt.Printf("Frame %4d, Display %d, Geometry %8d\r", iframe, idisplay, igeometry)
        nodes := builder.Render(geometry)
        sceneNodes = append(sceneNodes, nodes...)
      }
    }
    iroot := uint32(len(doc.Nodes))
    root := gltf.Node{
      Name    : fmt.Sprintf("Frame %d", iframe),
      Children: sceneNodes,
    }
    doc.Nodes = append(doc.Nodes, &root)
    allNodes = append(allNodes, iroot)
    if useScenes {
      scene := gltf.Scene{
        Name : fmt.Sprintf("Frame %d", iframe),
        Nodes: []uint32{iroot},
      }
      doc.Scenes = append(doc.Scenes, &scene)
    }
  }
  fmt.Printf("                                             \r")

  doc.Scenes[0].Nodes = append(doc.Scenes[0].Nodes, allNodes...)
  if useScenes {
    doc.Scene = gltf.Index(0)
  }

  fmt.Printf("Images:    %d\n", len(doc.Images))
  fmt.Printf("Materials: %d\n", len(doc.Materials))
  fmt.Printf("Meshes:    %d\n", len(doc.Meshes))
  fmt.Printf("Nodes:     %d\n", len(doc.Nodes))
  fmt.Printf("Scenes:    %d\n", len(doc.Scenes))

  if err := gltf.SaveBinary(doc, outname); err != nil {
    glog.Fatalf("Failed writing scenes to %s: %v\n", outname, err)
  }

}
