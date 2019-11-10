package infovis


import (
  "bufio"
  "fmt"
  "io/ioutil"
  "os"
  "regexp"
  "strconv"
  "strings"
  "time"
)


type Interpreter struct {
  verbose   bool
  sources   map[Label]Source
  sinks     map[Label]Sink
  relays    map[Label]*Relay
  server    *Server
  tokenizer *regexp.Regexp
}


func NewInterpreter() *Interpreter {
  var this = Interpreter{
    verbose  : false                   ,
    sources  : make(map[Label]Source)  ,
    sinks    : make(map[Label]Sink  )  ,
    relays   : make(map[Label]*Relay)  ,
    tokenizer: regexp.MustCompile(" +"),
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
  source, ok := this.sources[label];
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


func (this *Interpreter) assertNoSource(label Label) bool {
  if _, ok := this.sources[label]; ok {
    fmt.Printf("Source %s already exists.\n", label)
    return false
  }
  return true
}


func (this *Interpreter) assertNoSink(label Label) bool {
  if _, ok := this.sinks[label]; ok {
    fmt.Printf("Sink %s already exists.\n", label)
    return false
  }
  return true
}


func (this *Interpreter) assertNoRelay(label Label) bool {
  if _, ok := this.relays[label]; ok {
    fmt.Printf("Relay %s already exists.\n", label)
    return false
  }
  return true
}


func (this *Interpreter) Repl() {
  var reader = bufio.NewReader(os.Stdin)
  for {
    fmt.Print("> ")
    line, _ := reader.ReadString('\n')
    this.InterpretLine(line)
  }
}


func (this *Interpreter) InterpretLine(line string) bool {
  return this.InterpretTokens(this.tokenizer.Split(strings.TrimSuffix(line, "\n"), -1))
}


func (this *Interpreter) InterpretTokens(tokens []string) bool {

  switch tokens[0] {

    case "verbose":
      if checkArguments(tokens, "The 'verbose' command takes no arguments.", 1, true) {
        this.verbose = true
        return true
      }

    case "silent":
      if checkArguments(tokens, "The 'silent' command takes no arguments.", 1, true) {
        this.verbose = false
        return true
      }

    case "sources":
      if checkArguments(tokens, "The 'sources' command takes no arguments.", 1, true) {
        for label, _ := range this.sources {
          fmt.Printf("%s ", label)
        }
        fmt.Println()
        return true
      }

    case "sinks":
      if checkArguments(tokens, "The 'sinks' command takes no arguments.", 1, true) {
        for label, _ := range this.sinks {
          fmt.Printf("%s", label)
        }
        fmt.Println()
        return true
      }

    case "relays":
      if checkArguments(tokens, "The 'relays' command takes no arguments.", 1, true) {
        for label, relay := range this.relays {
          fmt.Printf("%s{%v,%v} ", label, relay.SourceLabels(), relay.SinkLabels())
        }
        fmt.Println()
        return true
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
        if found {
          return true
        }
        fmt.Printf("%s is neither a source, sink, or relay.\n", label)
      }

    case "reset":
      for _, label := range tokens[1:] {
        if source, ok := this.lookupSource(label); ok {
          source.Reset()
        } else {
          return false
        }
      }
      return true

    case "absorber":
      if checkArguments(tokens, "The 'absorber' command must name a channel.", 2, true) && this.assertNoSink(tokens[1]) {
        this.sinks[tokens[1]] = NewAbsorber(tokens[1], this.verbose)
        return true
      }

    case "printer":
      if checkArguments(tokens, "The 'printer' command must name a channel and a kind of protocol buffer.", 3, true) && this.assertNoSink(tokens[1]) {
        this.sinks[tokens[1]] = NewPrinter(tokens[1], tokens[2], this.verbose)
        return true
      }

    case "files":
      if checkArguments(tokens, "The 'files' command must name a channel.", 2, false) && this.assertNoSource(tokens[1]) {
        this.sources[tokens[1]] = NewFiles(tokens[1], tokens[2:], this.verbose)
        return true
      }

    case "append":
      if checkArguments(tokens, "The 'file' command must name a file source.", 2, false) {
        if source, ok := this.lookupSource(tokens[1]); ok {
          if files, ok := source.(*Files); ok {
            files.Append(tokens[2:])
            return true
          }
          fmt.Printf("The source %s is not a file source.\n", tokens[1])
        }
      }

    case "relay":
      if checkArguments(tokens, "The 'relay' command must have one argument.", 2, true) && this.assertNoRelay(tokens[1]) {
        this.relays[tokens[1]] = NewRelay(tokens[1], this.verbose)
        return true
      }

    case "add-source":
      if checkArguments(tokens, "The 'add' command must name a relay.", 2, false) {
        if relay, ok := this.lookupRelay(tokens[1]); ok {
          for _, label := range tokens[2:] {
            if source, ok := this.lookupSource(label); ok {
              relay.AddSource(label, source, this.verbose)
            } else {
              return false
            }
          }
        }
      }
      return true

    case "add-sink":
      if checkArguments(tokens, "The 'add' command must name a relay.", 2, false) {
        if relay, ok := this.lookupRelay(tokens[1]); ok {
          for _, label := range tokens[2:] {
            if sink, ok := this.lookupSink(label); ok {
              relay.AddSink(label, sink)
            } else {
              return false
            }
          }
        }
      }
      return true

    case "remove-source":
      if checkArguments(tokens, "The 'remove' command must name a relay.", 2, false) {
        if relay, ok := this.lookupRelay(tokens[1]); ok {
          for _, label := range tokens[2:] {
            if _, ok := this.lookupSource(label); ok {
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
        if relay, ok := this.lookupRelay(tokens[1]); ok {
          for _, label := range tokens[2:] {
            if _, ok := this.lookupSink(label); ok {
              relay.RemoveSink(label)
            } else {
              return false
            }
          }
        }
      }
      return true

    case "filter":
      fmt.Println("The 'filter' command is not yet implemented.")

    case "serve":
      if checkArguments(tokens, "The 'serve' command must have an address and a path.", 3, true) {
        this.server = NewServer(tokens[1], tokens[2], this.verbose)
        return true
      }

    case "websocket":
      if checkArguments(tokens, "The 'websocket' command must have a path.", 2, true) && this.assertNoSource(tokens[1]) && this.assertNoSink(tokens[1]) {
        websocket := NewWebsocket(this.server, tokens[1], this.verbose)
        this.sources[tokens[1]] = websocket
        this.sinks[tokens[1]]   = websocket
        return true
      }

    case "kafka":
      fmt.Println("The 'kafka' command is not yet implemented.")

    case "script":
      for _, file := range tokens[1:] {
        content, err := ioutil.ReadFile(file)
        if err != nil {
          fmt.Printf("Failed to read file %s: %v.\n", file, err)
          return false
        }
        for _, line := range strings.Split(string(content), "\n") {
          if this.verbose {
            fmt.Printf(">> %s\n", line)
          }
          if !this.InterpretLine(line) {
            return false
          }
        }
      }
      return true

    case "sleep":
      if checkArguments(tokens, "The 'sleep' command must specify the number of seconds.", 2, true) {
        delay, err := strconv.ParseUint(tokens[1], 10, 32)
        if err == nil {
          time.Sleep(time.Duration(delay) * time.Second)
          return true
        }
        fmt.Printf("Could not parse whole number %s: %v.\n", tokens[1], err)
      }

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
      fmt.Println("script [file]...")
      fmt.Println("sleep 'seconds'")
      fmt.Println("exit")
      fmt.Println("help")
      return true

    case "":
      return true

    default:
      fmt.Printf("Illegal command '%v'.\n", tokens)

  }

  return false

}
