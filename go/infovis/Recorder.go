package infovis


import (
  "fmt"
  "io/ioutil"
  "github.com/golang/glog"
)


type Recorder struct {
  label   Label
  channel ProtobufChannel
  done    DoneChannel
}


func NewRecorder(label Label, prefix string, reaper LabelInChannel) *Recorder {

  var recorder = Recorder {
    label  : label                ,
    channel: make(ProtobufChannel),
    done   : make(DoneChannel)    ,
  }

  go func() {
    <-recorder.done
    reaper <- recorder.label
  }()

  go func() {
    var sequence int = 0
    defer glog.Infof("Recorder %s is closing.\n", recorder.label)
    defer close(recorder.channel)
    for {
      select {
        case buffer, ok := <-recorder.channel:
          if !ok {
            glog.Errorf("Receive failed for recorder %s.\n", recorder.label)
            recorder.Exit()
            return
          }
          glog.Infof("Recorder %s received %v bytes.\n", recorder.label, len(buffer))
          filename := fmt.Sprintf("%s-%06d.pbb", prefix, sequence)
          if err := ioutil.WriteFile(filename, buffer, 0640); err != nil {
              glog.Errorf("Write failed for recorder %s: %v.\n", recorder.label, err)
              recorder.Exit()
              return
          }
          sequence++
          glog.Infof("Recorder %s wrote %v bytes to %s.\n", recorder.label, len(buffer), filename)
        case <-recorder.done:
          return
      }
    }
  }()

  return &recorder

}


func (recorder *Recorder) Label() Label {
  return recorder.label
}


func (recorder *Recorder) In() ProtobufInChannel {
  return recorder.channel
}


func (recorder *Recorder) Exit() {
  select {
    case <-recorder.done:
    default:
      close(recorder.done)
  }
}


func (recorder *Recorder) Alive() bool {
  select {
    case <-recorder.done:
      return false
    default:
      return true
  }
}
