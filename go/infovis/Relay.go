package infovis


import (
  "log"
  "sync"
  "github.com/golang/protobuf/proto"
)


type Conversion int

const (
  ConvertShow   Conversion = iota
  ConvertView
  ConvertTool
  ConvertOffset
)


func ParseConversion(text string) (Conversion, bool) {
  switch text {
    case "show":
      return ConvertShow, true
    case "view":
      return ConvertView, true
    case "tool":
      return ConvertTool, true
    case "offset":
      return ConvertOffset, true
    default:
       return 0, false
  }
}


func convertBuffer(conversions []Conversion, buffer *[]byte, verbose bool) (*[]byte, bool) {

  if len(conversions) == 0 {
    return buffer, true
  }

  request := Request{}
  response := Response{}
  if err := proto.Unmarshal(*buffer, &response); err != nil {
    if verbose {
      log.Printf("Converter %s failed to unmarshal buffer: %v.\n", err)
    }
    return buffer, false
  }

  for _, conversion := range conversions {
    switch conversion {
      case ConvertShow:
        request.Show = response.Shown
      case ConvertView:
        request.Viewloc = response.Viewloc
      case ConvertTool:
        request.Toolloc = response.Toolloc
      case ConvertOffset:
        request.Offsetloc = response.Offsetloc
    }
  }

  bufferNew, err := proto.Marshal(&request)
  if err != nil {
    if verbose {
      log.Printf("Converter %s failed to marshal request %v: %v.\n", request, err)
    }
    return buffer, false
  }

  return &bufferNew, true

}


type Relay struct {
  label   Label
  sources map[Label]Source
  sinks   map[Label]Sink
  merge   ProtobufChannel
  exit    bool
  mux     sync.RWMutex
}


func NewRelay(label Label, conversions []Conversion, verbose bool) *Relay {

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
      converted, ok := convertBuffer(conversions, &buffer, verbose)
      if !ok {
        continue
      }
      for _, sink := range this.Sinks() {
        *sink.In() <- *converted
        if verbose {
          log.Printf("Relay %s wrote %v bytes to sink %s.\n", this.label, len(*converted), sink.Label())
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
  this.mux.RLock()
  sources := make([]Source, 0, len(this.sources))
  for _, source := range this.sources {
    sources = append(sources, source)
  }
  this.mux.RUnlock()
  return sources
}


func (this *Relay) Sinks() []Sink {
  this.mux.RLock()
  sinks := make([]Sink, 0, len(this.sinks))
  for _, sink := range this.sinks {
    sinks = append(sinks, sink)
  }
  this.mux.RUnlock()
  return sinks
}


func (this *Relay) SourceLabels() []Label {
  this.mux.RLock()
  labels := make([]Label, 0, len(this.sources))
  for label, _ := range this.sources {
    labels = append(labels, label)
  }
  this.mux.RUnlock()
  return labels
}


func (this *Relay) SinkLabels() []Label {
  this.mux.RLock()
  labels := make([]Label, 0, len(this.sinks))
  for label, _ := range this.sinks {
    labels = append(labels, label)
  }
  this.mux.RUnlock()
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
      this.mux.RLock()
      _, ok = this.sources[label]
      this.mux.RUnlock()
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
