package infovis


import (
  "bufio"
  "fmt"
  "os"
  "regexp"
  "strings"
)


type Interpreter struct {
  verbose bool
  sources map[Label]Source
  sinks   map[Label]Sink
  relays  map[Label]*Relay
  server  *Server
}


func NewInterpreter() *Interpreter {
  var this = Interpreter{
    verbose: false                 ,
    sources: make(map[Label]Source),
    sinks  : make(map[Label]Sink  ),
    relays : make(map[Label]*Relay),
  }
  return &this
}


func checkArguments(tokens []string, message string, count int, exact bool) bool {
  if exact && len(tokens) != count || len(tokens) < count {
    fmt.Println(message)
    return false
  }
  return true
}


func (this *Interpreter) lookupSource(label Label) (Source, bool) {
  source, ok := this.sources[label]
  if !ok {
    fmt.Printf("Source %s does not exist.\n", label)
    return nil, false
  }
  return source, true
}


func (this *Interpreter) lookupSink(label Label) (Sink, bool) {
  sink, ok := this.sinks[label]
  if !ok {
    fmt.Printf("Sink %s does not exist.\n", label)
    return nil, false
  }
  return sink, true
}


func (this *Interpreter) lookupRelay(label Label) (*Relay, bool) {
  relay, ok := this.relays[label]
  if !ok {
    fmt.Printf("Relay %s does not exist.\n", label)
    return nil, false
  }
  return relay, true
}


func (this *Interpreter) Repl() {

  var reader = bufio.NewReader(os.Stdin)
  var tokenizer = regexp.MustCompile(" +")

  for {
    fmt.Print("> ")
    line, _ := reader.ReadString('\n')
    line = strings.TrimSuffix(line, "\n")
    tokens := tokenizer.Split(line, -1)
    if !this.Interpret(tokens) {
      fmt.Printf("Illegal command '%s'.\n", tokens)
    }
  }
}


func (this *Interpreter) Interpret(tokens []string) bool {

  switch tokens[0] {

    case "verbose":
      if checkArguments(tokens, "The 'verbose' command takes no arguments.", 1, true) {
        this.verbose = true
      }

    case "silent":
      if checkArguments(tokens, "The 'silent' command takes no arguments.", 1, true) {
        this.verbose = false
      }

    case "sources":
      if checkArguments(tokens, "The 'sources' command takes no arguments.", 1, true) {
        for label, _ := range this.sources {
          fmt.Printf("%s ", label)
        }
        fmt.Println()
      }

    case "sinks":
      if checkArguments(tokens, "The 'sinks' command takes no arguments.", 1, true) {
        for label, _ := range this.sinks {
          fmt.Printf("%s", label)
        }
        fmt.Println()
      }

    case "relays":
      if checkArguments(tokens, "The 'relays' command takes no arguments.", 1, true) {
        for label, relay := range this.relays {
          fmt.Printf("%s{%v,%v} ", label, relay.SourceLabels(), relay.SinkLabels())
        }
        fmt.Println()
      }

    case "delete":
      for _, label := range tokens[1:] {
        var found = false
        if source, ok := this.sources[label]; ok {
          source.Exit()
          delete(this.sources, label)
          found = true
        }
        if sink, ok := this.sinks[label]; ok {
          sink.Exit()
          delete(this.sinks, label)
          found = true
        }
        if relay, ok := this.relays[label]; ok {
          relay.Exit()
          delete(this.relays, label)
          found = true
        }
        if !found {
          fmt.Printf("%s is neither a source, sink, or relay.\n", label)
        }
      }

    case "reset":
      for _, label := range tokens[1:] {
        if source, ok := this.lookupSource(label); ok {
          source.Reset()
        }
      }

    case "absorber":
      if checkArguments(tokens, "The 'absorber' command must name a channel.", 2, true) {
        this.sinks[tokens[1]] = NewAbsorber(tokens[1], this.verbose)
      }

    case "printer":
      if checkArguments(tokens, "The 'printer' command must name a channel and a kind of protocol buffer.", 3, true) {
        this.sinks[tokens[1]] = NewPrinter(tokens[1], tokens[2], this.verbose)
      }

    case "files":
      if checkArguments(tokens, "The 'files' command must name a channel.", 2, false) {
        this.sources[tokens[1]] = NewFiles(tokens[1], tokens[2:], this.verbose)
      }

    case "append":
      if checkArguments(tokens, "The 'file' command must name a file source.", 2, false) {
        if source, ok := this.lookupSource(tokens[1]); ok {
          files, ok := source.(*Files)
          if !ok {
            fmt.Printf("The source %s is not a file source.\n", tokens[1])
          }
          files.Append(tokens[2:])
        }
      }

    case "relay":
      if checkArguments(tokens, "The 'relay' command must have one argument.", 2, true) {
        this.relays[tokens[1]] = NewRelay(tokens[1], this.verbose)
      }

    case "add-source":
      if checkArguments(tokens, "The 'add' command must name a relay.", 2, false) {
        if relay, ok := this.lookupRelay(tokens[1]); ok {
          for _, label := range tokens[2:] {
            if source, ok := this.lookupSource(label); ok {
              relay.AddSource(label, source, this.verbose)
            }
          }
        }
      }

    case "add-sink":
      if checkArguments(tokens, "The 'add' command must name a relay.", 2, false) {
        if relay, ok := this.lookupRelay(tokens[1]); ok {
          for _, label := range tokens[2:] {
            if sink, ok := this.lookupSink(label); ok {
              relay.AddSink(label, sink)
            }
          }
        }
      }

    case "remove-source":
      if checkArguments(tokens, "The 'remove' command must name a relay.", 2, false) {
        if relay, ok := this.lookupRelay(tokens[1]); ok {
          for _, label := range tokens[2:] {
            if _, ok := this.lookupSource(label); ok {
              relay.RemoveSource(label)
            }
          }
        }
      }

    case "remove-sink":
      if checkArguments(tokens, "The 'remove' command must name a relay.", 2, false) {
        if relay, ok := this.lookupRelay(tokens[1]); ok {
          for _, label := range tokens[2:] {
            if _, ok := this.lookupSink(label); ok {
              relay.RemoveSink(label)
            }
          }
        }
      }

    case "filter":
      fmt.Println("The 'filter' command is not yet implemented.")

    case "serve":
      if checkArguments(tokens, "The 'serve' command must have an address and a path.", 3, true) {
        this.server = NewServer(tokens[1], tokens[2], this.verbose)
      }

    case "websocket":
      if checkArguments(tokens, "The 'websocket' command must have a path.", 2, true) {
        websocket := NewWebsocket(this.server, tokens[1], this.verbose)
        this.sources[tokens[1]] = websocket
        this.sinks[tokens[1]]   = websocket
      }

    case "kafka":
      fmt.Println("The 'kafka' command is not yet implemented.")

    case "exit":
      os.Exit(0)

    case "help":
      fmt.Println("verbose")
      fmt.Println("silent")
      fmt.Println("sources")
      fmt.Println("sinks")
      fmt.Println("relays")
      fmt.Println("delete [source|sink|relay]...")
      fmt.Println("reset [source]...")
      fmt.Println("absorber 'sink'")
      fmt.Println("printer 'sink'")
      fmt.Println("files 'source' [filename]...")
      fmt.Println("append 'source' [filename]...")
      fmt.Println("relay 'relay'")
      fmt.Println("add-source 'relay' [source]...")
      fmt.Println("add-sink 'relay' [sink]...")
      fmt.Println("remove-source 'relay' [source]...")
      fmt.Println("remove-sink 'relay' [sink]...")
      fmt.Println("serve 'address' 'path'")
      fmt.Println("websocket 'path'")
      fmt.Println("exit")
      fmt.Println("help")

    case "":

    default:
      return false

  }

  return true

}
