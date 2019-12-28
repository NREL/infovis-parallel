package infovis


type Label = string


type ProtobufChannel = chan []byte


type DoneChannel = chan interface{}


type Connectable interface {
  Label() Label
  Exit()
  Alive() bool
}

type Source interface {
  Connectable
  Out() *ProtobufChannel
  Reset()
}


type Sink interface {
  Connectable
  In() *ProtobufChannel
}
