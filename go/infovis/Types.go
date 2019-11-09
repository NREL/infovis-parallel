package infovis


type Label = string


type ProtobufChannel = chan []byte


type Connectable interface {
  Label() Label
  Exit()
  Alive() bool
}

type Source interface {
  Connectable
  Out() *ProtobufChannel
  Append(arguments []string)
  Reset()
}


type Sink interface {
  Connectable
  In() *ProtobufChannel
}
