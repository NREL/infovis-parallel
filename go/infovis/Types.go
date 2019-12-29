package infovis


type Label = string


type LabelChannel = chan Label


type LabelInChannel = chan<- Label


type ProtobufChannel = chan []byte


type ProtobufInChannel = chan<- []byte


type ProtobufOutChannel = <-chan []byte


type DoneChannel = chan interface{}


type Connectable interface {
  Label() Label
  Exit()
  Alive() bool
}


type Source interface {
  Connectable
  Out() ProtobufOutChannel
  Reset()
}


type Sink interface {
  Connectable
  In() ProtobufInChannel
}
