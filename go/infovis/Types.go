package infovis


type ProtobufChannel = chan []byte


type Label = string


type Targets = map[Label]*ProtobufChannel


type Source interface {
  Label() Label
  Out() *ProtobufChannel
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
