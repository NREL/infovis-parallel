package infovis


import (
  "log"
)


func Relay(source Source, sink Sink) {
  var in = source.Out()
  var out = sink.In()
  for {
    buffer := <-*in
    log.Println("Relay", len(buffer), "bytes.")
    *out <- buffer
  }
}
