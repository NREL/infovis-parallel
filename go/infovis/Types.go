package infovis


type Label = string


type ProtobufChannel = chan []byte


type Source interface {
  Label() Label
  Out() *ProtobufChannel
  Append(arguments []string)
  Reset()
  Exit()
  Alive() bool
}


type Sink interface {
  Label() Label
  In() *ProtobufChannel
  Exit()
  Alive() bool
}
