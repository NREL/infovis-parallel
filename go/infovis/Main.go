package infovis


import (
  "bufio"
  "fmt"
  "os"
  "regexp"
  "strings"
)


func checkArguments(tokens []string, message string, count int, exact bool) bool {
  if exact && len(tokens) != count || len(tokens) < count {
    fmt.Println(message)
    return false
  } else {
    return true
  }
}


func lookupSource(sources map[Label]Source, label Label) (Source, bool) {
  source, ok := sources[label]
  if !ok {
    fmt.Println("Source", label, "does not exist.")
    return nil, false
  } else {
    return source, true
  }
}


func lookupSink(sinks map[Label]Sink, label Label) (Sink, bool) {
  sink, ok := sinks[label]
  if !ok {
    fmt.Println("Sink", label, "does not exist.")
    return nil, false
  } else {
    return sink, true
  }
}


func lookupRelay(relays map[Label]*Relay, label Label) (*Relay, bool) {
  relay, ok := relays[label]
  if !ok {
    fmt.Println("Relay", label, "does not exist.")
    return nil, false
  } else {
    return relay, true
  }
}


func Main() {

  var verbose = false

  var sources = make(map[Label]Source)
  var sinks   = make(map[Label]Sink  )
  var relays  = make(map[Label]*Relay )

  var server  *Server = nil

  var reader = bufio.NewReader(os.Stdin)

  var tokenizer = regexp.MustCompile(" +")

  for {

    fmt.Print("> ")
    line, _ := reader.ReadString('\n')
    line = strings.TrimSuffix(line, "\n")
    tokens := tokenizer.Split(line, -1)

    switch tokens[0] {

      case "verbose":
        if checkArguments(tokens, "The 'verbose' command takes no arguments.", 1, true) {
          verbose = true
        }

      case "silent":
        if checkArguments(tokens, "The 'silent' command takes no arguments.", 1, true) {
          verbose = false
        }

      case "sources":
        if checkArguments(tokens, "The 'sources' command takes no arguments.", 1, true) {
          for label, _ := range sources {
            fmt.Printf("%s ", label)
          }
          fmt.Println()
        }

      case "sinks":
        if checkArguments(tokens, "The 'sinks' command takes no arguments.", 1, true) {
          for label, _ := range sinks {
            fmt.Printf("%s", label)
          }
          fmt.Println()
        }

      case "relays":
        if checkArguments(tokens, "The 'relays' command takes no arguments.", 1, true) {
          for label, relay := range relays {
            fmt.Printf("%s{%v,%v} ", label, relay.SourceLabels(), relay.SinkLabels())
          }
          fmt.Println()
        }

      case "delete":
        for _, label := range tokens[1:] {
          if source, ok := sources[label]; ok {
            source.Exit()
            delete(sources, label)
          }
          if sink, ok := sinks[label]; ok {
            sink.Exit()
            delete(sinks, label)
          }
          if relay, ok := relays[label]; ok {
            relay.Exit()
            delete(relays, label)
          }
        }

      case "reset":
        for _, label := range tokens[1:] {
          if source, ok := sources[label]; ok {
            source.Reset()
          }
        }

      case "absorber":
        if checkArguments(tokens, "The 'absorber' command must name a channel.", 2, true) {
          sinks[tokens[1]] = NewAbsorber(tokens[1], verbose)
        }

      case "printer":
        if checkArguments(tokens, "The 'printer' command must name a channel.", 2, true) {
          sinks[tokens[1]] = NewPrinter(tokens[1], verbose)
        }

      case "files":
        if checkArguments(tokens, "The 'files' command must name a channel.", 2, false) {
          sources[tokens[1]] = NewFiles(tokens[1], tokens[2:], verbose)
        }

      case "append":
        if checkArguments(tokens, "The 'file' command must name a file source.", 2, false) {
          if source, ok := lookupSource(sources, tokens[1]); ok {
            source.Append(tokens[2:])
          }
        }

      case "relay":
        if checkArguments(tokens, "The 'relay' command must have one argument.", 2, true) {
          relays[tokens[1]] = NewRelay(tokens[1], verbose)
        }

      case "add-source":
        if checkArguments(tokens, "The 'add' command must name a relay.", 2, false) {
          if relay, ok := lookupRelay(relays, tokens[1]); ok {
            for _, label := range tokens[2:] {
              if source, ok := sources[label]; ok {
                relay.AddSource(label, source, verbose)
              }
            }
          }
        }

      case "add-sink":
        if checkArguments(tokens, "The 'add' command must name a relay.", 2, false) {
          if relay, ok := lookupRelay(relays, tokens[1]); ok {
            for _, label := range tokens[2:] {
              if sink, ok := sinks[label]; ok {
                relay.AddSink(label, sink)
              }
            }
          }
        }

      case "remove-source":
        if checkArguments(tokens, "The 'remove' command must name a relay.", 2, false) {
          if relay, ok := lookupRelay(relays, tokens[1]); ok {
            for _, label := range tokens[2:] {
              if _, ok := sources[label]; ok {
                relay.RemoveSource(label)
              }
            }
          }
        }

      case "remove-sink":
        if checkArguments(tokens, "The 'remove' command must name a relay.", 2, false) {
          if relay, ok := lookupRelay(relays, tokens[1]); ok {
            for _, label := range tokens[2:] {
              if _, ok := sinks[label]; ok {
                relay.RemoveSink(label)
              }
            }
          }
        }

      case "serve":
        if checkArguments(tokens, "The 'serve' command must have an address and a path.", 3, true) {
          server = NewServer(tokens[1], tokens[2], verbose)
        }

      case "websocket":
        if checkArguments(tokens, "The 'websocket' command must have a path.", 2, true) {
          websocket := NewWebsocket(server, tokens[1], verbose)
          sources[tokens[1]] = websocket
          sinks[tokens[1]]   = websocket
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
        fmt.Println("exit")
        fmt.Println("help")

      case "":

      default:
        fmt.Printf("Illegal command '%s'.\n", line)

    }

  }

}
