package main


import (
  "os"
  "bitbucket.org/bwbush/infovis-parallel/go/infovis"
)


func main() {
  interpreter := infovis.NewInterpreter()
  for _, file := range os.Args[1:] {
    interpreter.InterpretLine("script " + file)
  }
  interpreter.Repl()
}
