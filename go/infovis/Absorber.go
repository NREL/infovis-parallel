package infovis


import (
  "log"
)


type Absorber struct {
  label   Label
  channel ProtobufChannel
  exit    bool
}


func NewAbsorber(label Label, verbose bool) *Absorber {

  var absorber = Absorber {
    label  : label                ,
    channel: make(ProtobufChannel),
    exit   : false                ,
  }

  go func() {
    for !absorber.exit {
      buffer, ok := <-absorber.channel
      if !ok {
        log.Printf("Receive failed for absorber %s.\n", absorber.label)
        absorber.exit = true
        continue
      }
      if verbose {
        log.Printf("Absorber %s received %v bytes.\n", absorber.label, len(buffer))
      }
    }
    if verbose {
      log.Printf("Absorber %s is closing.\n", absorber.label)
    }
    close(absorber.channel)
  }()

  return &absorber

}


func (absorber *Absorber) Label() Label {
  return absorber.label
}


func (absorber *Absorber) In() *ProtobufChannel {
  return &absorber.channel
}


func (absorber *Absorber) Exit() {
  absorber.exit = true
}


func (absorber *Absorber) Alive() bool {
  return !absorber.exit
}
