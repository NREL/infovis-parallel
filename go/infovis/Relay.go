package infovis


import (
  "sync"
)


type Relay struct {
  label   Label
  sources map[Label]Source
  sinks   map[Label]Sink
  exit    bool
  mux     sync.Mutex
}


func NewRelay(label Label, verbose bool) *Relay {

  var this = Relay{
    label  : label                 ,
    sources: make(map[Label]Source),
    sinks  : make(map[Label]Sink  ),
    exit   : false                 ,
  }

  go func() {
  }()

  return &this

}


func (this *Relay) AddSource(label Label, source Source) {
  this.mux.Lock()
  this.sources[label] = source
  this.mux.Unlock()
}

func (this *Relay) AddSink(label Label, sink Sink) {
  this.mux.Lock()
  this.sinks[label] = sink
  this.mux.Unlock()
}


func (this *Relay) RemoveSource(label Label) {
  this.mux.Lock()
  delete(this.sources, label)
  this.mux.Unlock()
}

func (this *Relay) RemoveSink(label Label) {
  this.mux.Lock()
  delete(this.sinks, label)
  this.mux.Unlock()
}


func (this *Relay) Exit() {
  this.exit = true
}


func (this *Relay) Alive() bool {
  return !this.exit
}
