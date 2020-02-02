package main


import (
  "flag"
  "fmt"
  "os"
  "github.com/golang/glog"
  "bitbucket.org/bwbush/infovis-parallel/go/infovis"
)


func main() {

//infovis.NewJoystick(0)

  defer glog.Flush()

  var demo = flag.Bool("demo", false, "run in demo mode")

  flag.Usage = func() {
    fmt.Fprintf(os.Stderr, "Usage:\n")
    fmt.Fprintf(os.Stderr, "  go-infovis [options] [file]..\n")
    fmt.Fprintf(os.Stderr, "  go-infovis [options] -demo [bind-address] [websocket-path] [file]..\n")
    fmt.Fprintf(os.Stderr, "Options:\n")
    flag.PrintDefaults()
  }

  flag.Parse()
  args := flag.Args()

  if *demo && len(args) > 2 {
    infovis.Demo(args[0], args[1], args[2:])
    return
  }

  interpreter := infovis.NewInterpreter()
  for _, file := range args {
    interpreter.InterpretLine("script " + file)
  }
  interpreter.Repl()


}
