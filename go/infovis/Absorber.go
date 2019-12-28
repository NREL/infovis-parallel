package infovis


import (
  "github.com/golang/glog"
)


type Absorber struct {
  label   Label
  channel ProtobufChannel
  done    DoneChannel
}


func NewAbsorber(label Label) *Absorber {

  var absorber = Absorber {
    label  : label                ,
    channel: make(ProtobufChannel),
    done   : make(DoneChannel)    ,
  }

  go func() {
    defer glog.Infof("Absorber %s is closing.\n", absorber.label)
    defer close(absorber.channel)
    for {
      select {
        case buffer, ok := <-absorber.channel:
          if !ok { // FIXME: This can only happen if the channel is closed exertnally.
            glog.Errorf("Receive failed for absorber %s.\n", absorber.label)
            absorber.Exit()
            return
          }
          glog.Infof("Absorber %s received %v bytes.\n", absorber.label, len(buffer))
        case <-absorber.done:
          return
      }
    }
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
  close(absorber.done)
}


func (absorber *Absorber) Alive() bool {
  select {
    case <- absorber.done:
      return false
    default:
      return true
  }
}
