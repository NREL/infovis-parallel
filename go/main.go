package main


import (
  "os"
  "bitbucket.org/bwbush/infovis-parallel/go/infovis"
)


func main() {

  if len(os.Args) > 3 && os.Args[1] == "--demo" {
    infovis.Demo(os.Args[2], os.Args[3], os.Args[4:])
    return
  }

  interpreter := infovis.NewInterpreter()
  for _, file := range os.Args[1:] {
    interpreter.InterpretLine("script " + file)
  }
  interpreter.Repl()

}
