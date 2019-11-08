package infovis


import (
  "log"
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
        if verbose {
          log.Printf("Receive failed for printer %s\n.", this.label)
        }
        this.exit = true
        continue
      }
      if verbose {
        log.Printf("Printer %s received %v bytes\n.", this.label, len(buffer))
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
