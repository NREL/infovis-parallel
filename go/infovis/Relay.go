package infovis


import (
  "log"
  "sync"
  "github.com/golang/protobuf/proto"
)


type Filter int

const (
  FilterShow    Filter = iota
  FilterMessage
  FilterReset
  FilterUpsert
  FilterDelete
  FilterView
  FilterTool
  FilterOffset
)

var allFilters = []Filter{FilterShow, FilterMessage, FilterReset, FilterUpsert, FilterDelete, FilterView, FilterTool, FilterOffset}

func ParseFilter(text string) (Filter, bool) {
  switch text {
    case "show":
      return FilterShow, true
    case "message":
      return FilterMessage, true
    case "reset":
      return FilterReset, true
    case "upsert":
      return FilterUpsert, true
    case "delete":
      return FilterDelete, true
    case "view":
      return FilterView, true
    case "tool":
      return FilterTool, true
    case "offset":
      return FilterOffset, true
    default:
      return -1, false
  }
}

func InvertFilters(filters *[]Filter) (inversion []Filter) {
  var empty struct{}
  selection := make(map[Filter]struct{})
  for _, filter := range *filters {
    selection[filter] = empty
  }
  for _, filter := range allFilters {
    if _, ok := selection[filter]; !ok {
      inversion = append(inversion, filter)
    }
  }
  return
}


func filterBuffer(exclusions []Filter, buffer *[]byte) (*[]byte, bool) {

  request := Request{}
  if err := proto.Unmarshal(*buffer, &request); err != nil {
    log.Printf("Filter %s failed to unmarshal buffer: %v.\n", err)
    return buffer, false
  }

  for _, exclusion := range exclusions {
    switch exclusion{
      case FilterShow:
        request.Show = 0
      case FilterReset:
        request.Reset_ = false
      case FilterUpsert:
        request.Upsert = []*Geometry{}
      case FilterDelete:
        request.Delete = []int64{}
      case FilterView:
        request.Viewloc = nil
      case FilterTool:
        request.Toolloc = nil
      case FilterOffset:
        request.Offsetloc = nil
    }
  }

  bufferNew, err := proto.Marshal(&request)
  if err != nil {
    log.Printf("Filter %s failed to marshal request %v: %v.\n", request, err)
    return buffer, false
  }

  return &bufferNew, true

}


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
       return -1, false
  }
}


func convertBuffer(conversions []Conversion, buffer *[]byte) (*[]byte, bool) {

  if len(conversions) == 0 {
    return buffer, true
  }

  request := Request{}
  response := Response{}
  if err := proto.Unmarshal(*buffer, &response); err != nil {
    log.Printf("Converter %s failed to unmarshal buffer: %v.\n", err)
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
    log.Printf("Converter %s failed to marshal request %v: %v.\n", request, err)
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


func NewRelay(label Label, conversions []Conversion, filters []Filter, verbose bool) *Relay {

  var this = Relay{
    label  : label                 ,
    sources: make(map[Label]Source),
    sinks  : make(map[Label]Sink  ),
    merge  : make(ProtobufChannel) ,
    exit   : false                 ,
  }

  exclusions := InvertFilters(&filters)

  go func() {
    for !this.exit {
      buffer := <-this.merge
      converted, ok := convertBuffer(conversions, &buffer)
      if !ok {
        continue
      }
      filtered, ok := filterBuffer(exclusions, converted)
      for _, sink := range this.Sinks() {
        *sink.In() <- *filtered
        if verbose {
          log.Printf("Relay %s wrote %v bytes to sink %s.\n", this.label, len(*filtered), sink.Label())
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
        log.Printf("Relay %s source %s was closed.\n", this.label, label)
        return
      }
      this.mux.RLock()
      _, ok = this.sources[label]
      this.mux.RUnlock()
      if !ok {
        log.Printf("Relay %s source %s is no longer connected.\n", this.label, label)
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
