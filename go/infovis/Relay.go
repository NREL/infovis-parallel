package infovis


import (
  "fmt"
)


func Relay(source Source, sink Sink) {
  var in = source.Out()
  var out = sink.In()
  for {
    buffer := <-*in
    fmt.Println("Relay", len(buffer), "bytes.")
    *out <- buffer
  }
}
