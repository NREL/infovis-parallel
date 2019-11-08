package infovis


import (
  "log"
)


type Printer struct {
  label   Label
  channel ProtobufChannel
  exit    bool
}


func NewPrinter(label Label) *Printer {

  var this = Printer {
    label  : label                ,
    channel: make(ProtobufChannel),
    exit   : false                ,
  }

  go func() {
    for (!this.exit) {
      buffer, ok := <-this.channel
      if !ok {
        this.exit = true
        continue
      }
      log.Println("Printer", this.label, "received", len(buffer), "bytes.")
    }
    log.Println("Printer", this.label, " closed.")
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
