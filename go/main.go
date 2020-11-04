package main


import (
  "flag"
  "fmt"
  "os"
  "github.com/golang/glog"
  "bitbucket.org/bwbush/infovis-parallel/go/infovis"
  xport "bitbucket.org/bwbush/infovis-parallel/go/infovis/export"
  "bitbucket.org/bwbush/infovis-parallel/go/infovis/switchboard"
)


func main() {

//infovis.NewJoystick(0)

  defer glog.Flush()

  var demo   = flag.Bool("demo"  , false, "run in demo mode"      )
  var export = flag.Bool("export", false, "export buffers to glTF")

  flag.Usage = func() {
    fmt.Fprintf(os.Stderr, "Usage:\n")
    fmt.Fprintf(os.Stderr, "  go-infovis [options] [file]..\n")
    fmt.Fprintf(os.Stderr, "  go-infovis [options] -demo <bind-address> <websocket-path> <cert-file> <key-file> [file]..\n")
    fmt.Fprintf(os.Stderr, "  go-infovis [options] -export <out-file> [file]..\n")
    fmt.Fprintf(os.Stderr, "Options:\n")
    flag.PrintDefaults()
  }

  flag.Parse()
  args := flag.Args()

  if *demo && len(args) > 4 {
    infovis.Demo(args[0], args[1], args[2], args[3], args[4:])
    return
  }

  if *export && len(args) > 1 {
    xport.Export(args[1:], args[0], false, true)
    return
  }

  interpreter := switchboard.NewInterpreter()
  for _, file := range args {
    interpreter.InterpretLine("script " + file)
  }
  interpreter.Repl()


}
