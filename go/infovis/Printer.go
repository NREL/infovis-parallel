package infovis


import (
  "fmt"
  "log"
  "github.com/golang/protobuf/proto"
)


type Printer struct {
  label   Label
  channel ProtobufChannel
  exit    bool
}


func NewPrinter(label Label, kind string, verbose bool) *Printer {

  var printer = Printer {
    label  : label                ,
    channel: make(ProtobufChannel),
    exit   : false                ,
  }

  go func() {
    for !printer.exit {
      buffer, ok := <-printer.channel
      if !ok {
        log.Printf("Receive failed for printer %s\n.", printer.label)
        printer.exit = true
        continue
      }
      if verbose {
        log.Printf("Printer %s received %v bytes\n.", printer.label, len(buffer))
      }
      switch kind {
        case "Request":
          request := Request{}
          err := proto.Unmarshal(buffer, &request)
          if err != nil {
            log.Printf("Printer %s could not unmarshal %s: %v.\n", label, kind, err)
            break
          }
          fmt.Printf("Printer %s received %s: %v.\n", label, kind, request)
        case "Response":
          response := Response{}
          err := proto.Unmarshal(buffer, &response)
          if err != nil {
            log.Printf("Printer %s could not unmarshal %s: %v.\n", label, kind, err)
            break
          }
          fmt.Printf("Printer %s received %s: %v.\n", label, kind, response)
      }
    }
    if verbose {
      log.Printf("Printer %s is closing.\n", printer.label)
    }
    close(printer.channel)
  }()

  return &printer

}


func (printer *Printer) Label() Label {
  return printer.label
}


func (printer *Printer) In() *ProtobufChannel {
  return &printer.channel
}


func (printer *Printer) Exit() {
  printer.exit = true
}


func (printer *Printer) Alive() bool {
  return !printer.exit
}
