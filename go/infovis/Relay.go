package infovis


import (
  "log"
  "sync"
)


type Relay struct {
  label   Label
  sources map[Label]Source
  sinks   map[Label]Sink
  merge   ProtobufChannel
  exit    bool
  mux     sync.Mutex
}


func NewRelay(label Label, verbose bool) *Relay {

  var this = Relay{
    label  : label                 ,
    sources: make(map[Label]Source),
    sinks  : make(map[Label]Sink  ),
    merge  : make(ProtobufChannel) ,
    exit   : false                 ,
  }

  go func() {
    for !this.exit {
      buffer := <-this.merge
      for _, sink := range this.Sinks() {
        *sink.In() <- buffer
        if verbose {
          log.Printf("Relay %s wrote %v bytes to sink %s.\n", this.label, len(buffer), sink.Label())
        }
      }
    }
    if verbose {
      log.Printf("Relay %s is closing.\n", this.label)
    }
    close(this.merge)
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


func (this *Relay) AddSource(label Label, source Source, verbose bool) {
  this.mux.Lock()
  this.sources[label] = source
  this.mux.Unlock()
  go func() {
    for !this.exit {
      buffer, ok := <-*source.Out()
      if !ok {
        if verbose {
          log.Printf("Relay %s source %s was closed.\n", this.label, label)
        }
        return
      }
      this.mux.Lock()
      _, ok = this.sources[label]
      this.mux.Unlock()
      if !ok {
        if verbose {
          log.Printf("Relay %s source %s is no longer connected.\n", this.label, label)
          }
        return
      }
      this.merge <- buffer
      if verbose {
        log.Printf("Relay %s read %v bytes from source %s.\n", this.label, len(buffer), label)
      }
    }
  }()
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
