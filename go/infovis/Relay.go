package infovis


import (
  "log"
  "sync"
  "time"
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
    for !this.exit {
      var buffer []byte = nil
      for buffer == nil {
        for _, source := range this.Sources() {
          select { // FIME: Remove this spin loop.
            case buffer1, ok := <-*source.Out():
              if !ok {
                this.RemoveSource(source.Label())
              } else {
                buffer = buffer1
                if verbose {
                  log.Println("Relay", this.label, "read from", source.Label(), len(buffer), "bytes.")
                }
                goto End
              }
            case <-time.After(250 * time.Microsecond):
          }
        }
      }
      End:
      for _, sink := range this.Sinks() {
        *sink.In() <- buffer
        if verbose {
          log.Println("Relay", this.label, "wrote to", sink.Label(), len(buffer), "bytes.")
        }
      }
    }
    if verbose {
      log.Println("Relay", this.label, "closed.")
    }
  }()

  return &this

}


func (this *Relay) Sources() []Source {
  this.mux.Lock()
  sources := make([]Source, 0, len(this.sources))
  for _, source := range this.sources {
    sources = append(sources, source)
  }
  this.mux.Unlock()
  return sources
}


func (this *Relay) Sinks() []Sink {
  this.mux.Lock()
  sinks := make([]Sink, 0, len(this.sinks))
  for _, sink := range this.sinks {
    sinks = append(sinks, sink)
  }
  this.mux.Unlock()
  return sinks
}


func (this *Relay) SourceLabels() []Label {
  this.mux.Lock()
  labels := make([]Label, 0, len(this.sources))
  for label, _ := range this.sources {
    labels = append(labels, label)
  }
  this.mux.Unlock()
  return labels
}


func (this *Relay) SinkLabels() []Label {
  this.mux.Lock()
  labels := make([]Label, 0, len(this.sinks))
  for label, _ := range this.sinks {
    labels = append(labels, label)
  }
  this.mux.Unlock()
  return labels
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
