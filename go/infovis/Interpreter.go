package infovis


import (
  "bufio"
  "flag"
  "fmt"
  "io/ioutil"
  "os"
  "regexp"
  "strconv"
  "strings"
  "sync"
  "time"
  "github.com/golang/glog"
)


type Interpreter struct {
  sources   map[Label]Source
  sinks     map[Label]Sink
  relays    map[Label]*Relay
  server    *Server
  tokenizer *regexp.Regexp
  commenter *regexp.Regexp
  reaper    LabelChannel
  mux       sync.Mutex
}


func NewInterpreter() *Interpreter {

  var interpreter = Interpreter{
    sources  : make(map[Label]Source)      ,
    sinks    : make(map[Label]Sink  )      ,
    relays   : make(map[Label]*Relay)      ,
    tokenizer: regexp.MustCompile(" +")    ,
    commenter: regexp.MustCompile(" *#.*$"),
    reaper   : make(LabelChannel)          ,
  }

  go func(){
    for {
      label := <-interpreter.reaper
      interpreter.mux.Lock()
      interpreter.deleteConnectable(label, false)
      interpreter.mux.Unlock()
    }
  }()

  return &interpreter

}


func checkArguments(tokens []string, message string, count int, exact bool) bool {
  if exact && len(tokens) != count || len(tokens) < count {
    glog.Warningln(message)
    return false
  }
  return true
}


func (interpreter *Interpreter) deleteConnectable(label Label, warn bool) bool {
  if source, ok := interpreter.sources[label]; ok {
    source.Exit()
    delete(interpreter.sources, label)
    return true
  }
  if sink, ok := interpreter.sinks[label]; ok {
    sink.Exit()
    delete(interpreter.sinks, label)
    return true
  }
  if relay, ok := interpreter.relays[label]; ok {
    relay.Exit()
    delete(interpreter.relays, label)
    return true
  }
  if warn {
    glog.Warningf("%s is neither a source, sink, or relay.\n", label)
  }
  return false
}


func (interpreter *Interpreter) lookupSource(label Label) (Source, bool) {
  source, ok := interpreter.sources[label]
  if !ok {
    glog.Warningf("Source %s does not exist.\n", label)
    return nil, false
  }
  return source, true
}


func (interpreter *Interpreter) lookupSink(label Label, allowRelays bool) (Sink, bool) {
  sink, ok := interpreter.sinks[label]
  if !ok {
    if allowRelays {
      sink, ok = interpreter.relays[label]
      if !ok {
        glog.Warningf("%s is neither a sink or relay.\n", label)
        return nil, false
      }
      return sink, true
    }
    glog.Warningf("Sink %s does not exist.\n", label)
    return nil, false
  }
  return sink, true
}


func (interpreter *Interpreter) lookupRelay(label Label) (*Relay, bool) {
  relay, ok := interpreter.relays[label]
  if !ok {
    glog.Warningf("Relay %s does not exist.\n", label)
    return nil, false
  }
  return relay, true
}


func (interpreter *Interpreter) assertNoConnectable(label Label) bool {
  if _, ok := interpreter.sources[label]; ok {
    glog.Warningf("Source %s already exists.\n", label)
    return false
  }
  if _, ok := interpreter.sinks[label]; ok {
    glog.Warningf("Channel %s already exists.\n", label)
    return false
  }
  if _, ok := interpreter.relays[label]; ok {
    glog.Warningf("Relay %s already exists.\n", label)
    return false
  }
  return true
}


func (interpreter *Interpreter) Repl() {
  var reader = bufio.NewReader(os.Stdin)
  for {
    line, ok := reader.ReadString('\n')
    if ok != nil {
      return
    }
    interpreter.InterpretLine(line)
  }
}


func (interpreter *Interpreter) InterpretLine(line string) bool {
  line = strings.TrimSpace(line)
  line = interpreter.commenter.ReplaceAllLiteralString(line, "")
  return interpreter.InterpretTokens(interpreter.tokenizer.Split(line, -1))
}


func (interpreter *Interpreter) InterpretTokens(tokens []string) bool {

  interpreter.mux.Lock()
  defer interpreter.mux.Unlock()

  switch tokens[0] {

    case "verbose":
      if checkArguments(tokens, "The 'verbose' command takes no arguments.", 1, true) {
        flag.Set("stderrthreshold", "INFO")
        return true
      }

    case "silent":
      if checkArguments(tokens, "The 'silent' command takes no arguments.", 1, true) {
        flag.Set("stderrthreshold", "WARNING")
        return true
      }

    case "sources":
      if checkArguments(tokens, "The 'sources' command takes no arguments.", 1, true) {
        fmt.Print("=")
        for label := range interpreter.sources {
          fmt.Printf(" %s", label)
        }
        fmt.Println()
        return true
      }

    case "sinks":
      if checkArguments(tokens, "The 'sinks' command takes no arguments.", 1, true) {
        fmt.Print("=")
        for label := range interpreter.sinks {
          fmt.Printf(" %s", label)
        }
        fmt.Println()
        return true
      }

    case "relays":
      if checkArguments(tokens, "The 'relays' command takes no arguments.", 1, true) {
        fmt.Print("=")
        for label, relay := range interpreter.relays {
          fmt.Printf(" %s{%v,%v}", label, relay.SourceLabels(), relay.SinkLabels())
        }
        fmt.Println()
        return true
      }

    case "delete":
      for _, label := range tokens[1:] {
        if !interpreter.deleteConnectable(label, true) {
          return false
        }
      }
      return true

    case "reset":
      for _, label := range tokens[1:] {
        if source, ok := interpreter.lookupSource(label); ok {
          source.Reset()
        } else {
          return false
        }
      }
      return true

    case "absorber":
      if checkArguments(tokens, "The 'absorber' command must name a channel.", 2, true) && interpreter.assertNoConnectable(tokens[1]) {
        interpreter.sinks[tokens[1]] = NewAbsorber(tokens[1], interpreter.reaper)
        return true
      }

    case "printer":
      if checkArguments(tokens, "The 'printer' command must name a channel and a kind of protocol buffer.", 3, true) && interpreter.assertNoConnectable(tokens[1]) {
        interpreter.sinks[tokens[1]] = NewPrinter(tokens[1], tokens[2], interpreter.reaper)
        return true
      }

    case "files":
      if checkArguments(tokens, "The 'files' command must name a channel.", 2, false) && interpreter.assertNoConnectable(tokens[1]) {
        interpreter.sources[tokens[1]] = NewFiles(tokens[1], tokens[2:], interpreter.reaper)
        return true
      }

    case "append":
      if checkArguments(tokens, "The 'file' command must name a file source.", 2, false) {
        if source, ok := interpreter.lookupSource(tokens[1]); ok {
          if files, ok := source.(*Files); ok {
            files.Append(tokens[2:])
            return true
          }
          glog.Warningf("The source %s is not a file source.\n", tokens[1])
        }
      }

    case "relay":
      if checkArguments(tokens, "The 'relay' command must have one argument.", 2, true) && interpreter.assertNoConnectable(tokens[1]) {
        interpreter.relays[tokens[1]] = NewRelay(tokens[1], []Conversion{}, []Filter{}, interpreter.reaper)
        return true
      }

    case "converter":
      if checkArguments(tokens, "The 'converter' command must name a relay.", 2, false) && interpreter.assertNoConnectable(tokens[1]) {
        conversions := make([]Conversion, 0, len(tokens) - 2)
        for _, token := range tokens[2:] {
          if conversion, ok := ParseConversion(token); ok {
            conversions = append(conversions, conversion)
          } else {
            glog.Warningf("The value '%s' is not a valid conversion.\n", token)
            return false
          }
        }
        interpreter.relays[tokens[1]] = NewRelay(tokens[1], conversions, []Filter{}, interpreter.reaper)
        return true
      }

    case "filter":
      if checkArguments(tokens, "The 'filter' command must name a relay.", 2, false) && interpreter.assertNoConnectable(tokens[1]) {
        filters := make([]Filter, 0, len(tokens) - 2)
        for _, token := range tokens[2:] {
          if filter, ok := ParseFilter(token); ok {
            filters = append(filters, filter)
          } else {
            glog.Warningf("The value '%s' is not a valid filter.\n", token)
            return false
          }
        }
        interpreter.relays[tokens[1]] = NewRelay(tokens[1], []Conversion{}, InvertFilters(&filters), interpreter.reaper)
        return true
      }

    case "add-source":
      if checkArguments(tokens, "The 'add' command must name a relay.", 2, false) {
        if relay, ok := interpreter.lookupRelay(tokens[1]); ok {
          for _, label := range tokens[2:] {
            if source, ok := interpreter.lookupSource(label); ok {
              relay.AddSource(label, &source)
            } else {
              return false
            }
          }
        }
      }
      return true

    case "add-sink":
      if checkArguments(tokens, "The 'add' command must name a relay.", 2, false) {
        if relay, ok := interpreter.lookupRelay(tokens[1]); ok {
          for _, label := range tokens[2:] {
            if sink, ok := interpreter.lookupSink(label, true); ok {
              relay.AddSink(label, &sink)
            } else {
              return false
            }
          }
        }
      }
      return true

    case "remove-source":
      if checkArguments(tokens, "The 'remove' command must name a relay.", 2, false) {
        if relay, ok := interpreter.lookupRelay(tokens[1]); ok {
          for _, label := range tokens[2:] {
            if _, ok := interpreter.lookupSource(label); ok {
              relay.RemoveSource(label)
            } else {
              return false
            }
          }
        }
      }
      return true

    case "remove-sink":
      if checkArguments(tokens, "The 'remove' command must name a relay.", 2, false) {
        if relay, ok := interpreter.lookupRelay(tokens[1]); ok {
          for _, label := range tokens[2:] {
            if _, ok := interpreter.lookupSink(label, true); ok {
              relay.RemoveSink(label)
            } else {
              return false
            }
          }
        }
      }
      return true

    case "serve":
      if checkArguments(tokens, "The 'serve' command must have an address and a path.", 3, true) {
        interpreter.server = NewServer(tokens[1], tokens[2])
        return true
      }

    case "websocket":
      if checkArguments(tokens, "The 'websocket' command must have a path.", 2, true) && interpreter.assertNoConnectable(tokens[1]) {
        websocket := NewWebsocket(interpreter.server, tokens[1], interpreter.reaper)
        interpreter.sources[tokens[1]] = websocket
        interpreter.sinks[tokens[1]]   = websocket
        return true
      }

    case "kafka":
      if checkArguments(tokens, "The 'kafka' command must have an address, whether to start at the earliest offset, and a topic.", 4, true) && interpreter.assertNoConnectable(tokens[3]) {
        kafka := NewKafka(tokens[3], tokens[1], tokens[2] == "true", interpreter.reaper)
        interpreter.sources[tokens[3]] = kafka
        interpreter.sinks[tokens[3]]   = kafka
      }

    case "script":
      for _, file := range tokens[1:] {
        content, err := ioutil.ReadFile(file)
        if err != nil {
          glog.Warningf("Failed to read file %s: %v.\n", file, err)
          return false
        }
        for _, line := range strings.Split(string(content), "\n") {
          fmt.Printf("> %s\n", line)
          interpreter.mux.Unlock()
          if !interpreter.InterpretLine(line) {
            return false
          }
          interpreter.mux.Lock()
        }
      }
      return true

    case "wait":
      if checkArguments(tokens, "The 'wait' command must specify the number of seconds.", 2, true) {
        delay, err := strconv.ParseUint(tokens[1], 10, 32)
        if err == nil {
          time.Sleep(time.Duration(delay) * time.Second)
          return true
        }
        glog.Warningf("Could not parse whole number %s: %v.\n", tokens[1], err)
      }

    case "exit":
      os.Exit(0)

    case "help":
      fmt.Println("? absorber 'sink'")
      fmt.Println("? add-sink 'relay' [sink|relay]...")
      fmt.Println("? add-source 'relay' [source]...")
      fmt.Println("? append 'source' [filename]...")
      fmt.Println("? converter 'relay' [show] [view] [tool] [offset]")
      fmt.Println("? delete [source|sink|relay]...")
      fmt.Println("? exit")
      fmt.Println("? files 'source' [filename]...")
      fmt.Println("? filter 'relay' [show] [message] [reset] [upsert] [delete] [view] [tool] [offset]")
      fmt.Println("? help")
      fmt.Println("? kafka 'address' [true|false] 'topic'")
      fmt.Println("? printer 'sink' (Request|Response)")
      fmt.Println("? relay 'relay'")
      fmt.Println("? relays")
      fmt.Println("? remove-sink 'relay' [sink|relay]...")
      fmt.Println("? remove-source 'relay' [source]...")
      fmt.Println("? reset [source]...")
      fmt.Println("? script [file]...")
      fmt.Println("? serve 'address' 'path'")
      fmt.Println("? silent")
      fmt.Println("? sinks")
      fmt.Println("? sources")
      fmt.Println("? verbose")
      fmt.Println("? wait 'seconds'")
      fmt.Println("? websocket 'path'")
      return true

    case "":
      return true

    default:
      glog.Warningf("Illegal command %v.\n", tokens)

  }

  return false

}
