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


func NewRelay(label Label, conversions []Conversion, exclusions []Filter, verbose bool) *Relay {

  var relay = Relay{
    label  : label                 ,
    sources: make(map[Label]Source),
    sinks  : make(map[Label]Sink  ),
    merge  : make(ProtobufChannel) ,
    exit   : false                 ,
  }

  go func() {
    for !relay.exit {
      buffer := <-relay.merge
      converted, ok := convertBuffer(conversions, &buffer)
      if !ok {
        continue
      }
      filtered, ok := filterBuffer(exclusions, converted)
      for _, sink := range relay.Sinks() {
        *sink.In() <- *filtered
        if verbose {
          log.Printf("Relay %s wrote %v bytes to sink %s.\n", relay.label, len(*filtered), sink.Label())
        }
      }
    }
    if verbose {
      log.Printf("Relay %s is closing.\n", relay.label)
    }
    close(relay.merge)
  }()

  return &relay

}


func (relay *Relay) Sources() []Source {
  relay.mux.RLock()
  sources := make([]Source, 0, len(relay.sources))
  for _, source := range relay.sources {
    sources = append(sources, source)
  }
  relay.mux.RUnlock()
  return sources
}


func (relay *Relay) Sinks() []Sink {
  relay.mux.RLock()
  sinks := make([]Sink, 0, len(relay.sinks))
  for _, sink := range relay.sinks {
    sinks = append(sinks, sink)
  }
  relay.mux.RUnlock()
  return sinks
}


func (relay *Relay) SourceLabels() []Label {
  relay.mux.RLock()
  labels := make([]Label, 0, len(relay.sources))
  for label := range relay.sources {
    labels = append(labels, label)
  }
  relay.mux.RUnlock()
  return labels
}


func (relay *Relay) SinkLabels() []Label {
  relay.mux.RLock()
  labels := make([]Label, 0, len(relay.sinks))
  for label := range relay.sinks {
    labels = append(labels, label)
  }
  relay.mux.RUnlock()
  return labels
}


func (relay *Relay) AddSource(label Label, source Source, verbose bool) {
  relay.mux.Lock()
  relay.sources[label] = source
  relay.mux.Unlock()
  go func() {
    for !relay.exit {
      buffer, ok := <-*source.Out()
      if !ok {
        log.Printf("Relay %s source %s was closed.\n", relay.label, label)
        return
      }
      relay.mux.RLock()
      _, ok = relay.sources[label]
      relay.mux.RUnlock()
      if !ok {
        log.Printf("Relay %s source %s is no longer connected.\n", relay.label, label)
        return
      }
      relay.merge <- buffer
      if verbose {
        log.Printf("Relay %s read %v bytes from source %s.\n", relay.label, len(buffer), label)
      }
    }
  }()
}


func (relay *Relay) AddSink(label Label, sink Sink) {
  relay.mux.Lock()
  relay.sinks[label] = sink
  relay.mux.Unlock()
}


func (relay *Relay) RemoveSource(label Label) {
  relay.mux.Lock()
  delete(relay.sources, label)
  relay.mux.Unlock()
}


func (relay *Relay) RemoveSink(label Label) {
  relay.mux.Lock()
  delete(relay.sinks, label)
  relay.mux.Unlock()
}


func (relay *Relay) Exit() {
  relay.exit = true
}


func (relay *Relay) Alive() bool {
  return !relay.exit
}
