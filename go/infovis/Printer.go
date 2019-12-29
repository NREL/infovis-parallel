package infovis


import (
  "fmt"
  "github.com/golang/glog"
  "github.com/golang/protobuf/proto"
)


type Printer struct {
  label   Label
  channel ProtobufChannel
  done    DoneChannel
}


func NewPrinter(label Label, kind string, reaper LabelInChannel) *Printer {

  var printer = Printer {
    label  : label                ,
    channel: make(ProtobufChannel),
    done   : make(DoneChannel)    ,
  }

  go func() {
    <-printer.done
    reaper <- printer.label
  }()

  go func() {
    defer glog.Infof("Printer %s is closing.\n", printer.label)
    defer close(printer.channel)
    for {
      select {
        case buffer, ok := <-printer.channel:
          if !ok {
            glog.Errorf("Receive failed for printer %s\n.", printer.label)
            printer.Exit()
            return
          }
          glog.Infof("Printer %s received %v bytes.\n", printer.label, len(buffer))
          switch kind {
            case "Request":
              request := Request{}
              err := proto.Unmarshal(buffer, &request)
              if err != nil {
                glog.Warningf("Printer %s could not unmarshal %s: %v.\n", label, kind, err)
                break
              }
              fmt.Printf("= Printer %s received %s: %v.\n", label, kind, request)
            case "Response":
              response := Response{}
              err := proto.Unmarshal(buffer, &response)
              if err != nil {
                glog.Warningf("Printer %s could not unmarshal %s: %v.\n", label, kind, err)
                break
              }
              fmt.Printf("= Printer %s received %s: %v.\n", label, kind, response)
          }
        case <-printer.done:
          return
      }
    }
  }()

  return &printer

}


func (printer *Printer) Label() Label {
  return printer.label
}


func (printer *Printer) In() ProtobufInChannel {
  return printer.channel
}


func (printer *Printer) Exit() {
  select {
    case <-printer.done:
    default:
      close(printer.done)
  }
}


func (printer *Printer) Alive() bool {
  select {
    case <-printer.done:
      return false
    default:
      return true
  }
}
