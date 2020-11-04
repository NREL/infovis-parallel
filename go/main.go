package main


import (
  "flag"
  "fmt"
  "os"
  "github.com/golang/glog"
  "bitbucket.org/bwbush/infovis-parallel/go/infovis"
  "bitbucket.org/bwbush/infovis-parallel/go/infovis/export"
  "bitbucket.org/bwbush/infovis-parallel/go/infovis/switchboard"
)


func main() {

  export.Export([]string{
    "../protobuf/examples/axes.pbb"          ,
    "../protobuf/examples/corner-points.pbb" ,
    "../protobuf/examples/helices.pbb"       ,
    "../protobuf/examples/rectangles.pbb"    ,
    "../protobuf/examples/tmp/bslm-0[01].pbb",
    "../protobuf/examples/some-text.pbb"     ,
  }, "./example.glb", false)
  os.Exit(0)

//infovis.NewJoystick(0)

  defer glog.Flush()

  var demo = flag.Bool("demo", false, "run in demo mode")

  flag.Usage = func() {
    fmt.Fprintf(os.Stderr, "Usage:\n")
    fmt.Fprintf(os.Stderr, "  go-infovis [options] [file]..\n")
    fmt.Fprintf(os.Stderr, "  go-infovis [options] -demo [bind-address] [websocket-path] [cert-file] [key-file] [file]..\n")
    fmt.Fprintf(os.Stderr, "Options:\n")
    flag.PrintDefaults()
  }

  flag.Parse()
  args := flag.Args()

  if *demo && len(args) > 4 {
    infovis.Demo(args[0], args[1], args[2], args[3], args[4:])
    return
  }

  interpreter := switchboard.NewInterpreter()
  for _, file := range args {
    interpreter.InterpretLine("script " + file)
  }
  interpreter.Repl()


}
