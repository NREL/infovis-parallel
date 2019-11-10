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

  var this = Printer {
    label  : label                ,
    channel: make(ProtobufChannel),
    exit   : false                ,
  }

  go func() {
    for !this.exit {
      buffer, ok := <-this.channel
      if !ok {
        if verbose {
          log.Printf("Receive failed for printer %s\n.", this.label)
        }
        this.exit = true
        continue
      }
      if verbose {
        log.Printf("Printer %s received %v bytes\n.", this.label, len(buffer))
      }
      switch kind {
        case "Request":
          request := Request{}
          err := proto.Unmarshal(buffer, &request)
          if err != nil {
            if verbose {
              log.Printf("Printer %s could not unmarshal %s: %v.\n", label, kind, err)
            }
            break
          }
          fmt.Printf("Printer %s received %s: %v.\n", label, kind, request)
        case "Response":
          response := Response{}
          err := proto.Unmarshal(buffer, &response)
          if err != nil {
            if verbose {
              log.Printf("Printer %s could not unmarshal %s: %v.\n", label, kind, err)
            }
            break
          }
          fmt.Printf("Printer %s received %s: %v.\n", label, kind, response)
      }
    }
    if verbose {
      log.Printf("Printer %s is closing.\n", this.label)
    }
    close(this.channel)
  }()

  return &this

}


func (this *Printer) Label() Label {
  return this.label
}


func (this *Printer) In() *ProtobufChannel {
  return &this.channel
}


func (this *Printer) Exit() {
  this.exit = true
}


func (this *Printer) Alive() bool {
  return !this.exit
}
