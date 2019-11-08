package infovis


import (
  "fmt"
)


type Printer struct {
  label   Label
  channel ProtobufChannel
  exit    bool
}


func NewPrinter(label Label, verbose bool) *Printer {

  var this = Printer {
    label  : label                ,
    channel: make(ProtobufChannel),
    exit   : false                ,
  }

  go func() {
    for !this.exit {
      buffer, ok := <-this.channel
      if !ok {
        this.exit = true
        continue
      }
      if verbose {
        fmt.Println("Printer", this.label, "received", len(buffer), "bytes.")
      }
    }
    if verbose {
      fmt.Println("Printer", this.label, " closed.")
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
