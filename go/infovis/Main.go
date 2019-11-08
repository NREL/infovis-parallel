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
    fmt.Println("The source", label, "does not exist.")
    return nil, false
  } else {
    return source, true
  }
}


func lookupSink(sinks map[Label]Sink, label Label) (Sink, bool) {
  sink, ok := sinks[label]
  if !ok {
    fmt.Println("The sink", label, "does not exist.")
    return nil, false
  } else {
    return sink, true
  }
}


func Main() {

  var verbose = false
  var sources = make(map[Label]Source)
  var sinks   = make(map[Label]Sink  )

  var reader = bufio.NewReader(os.Stdin)

  var tokenizer = regexp.MustCompile(" +")

  for {

    fmt.Print("> ")
    line, _ := reader.ReadString('\n')
    tokens := tokenizer.Split(strings.TrimSuffix(line, "\n"), -1)

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
            fmt.Print(label, " ")
          }
          fmt.Println()
        }

      case "sinks":
        if checkArguments(tokens, "The 'sinks' command takes no arguments.", 1, true) {
          for label, _ := range sinks {
            fmt.Print(label, " ")
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

      case "relay":
        if checkArguments(tokens, "The 'relay' command must have no arguments.", 1, true) {
          NewRelay(tokens[1], verbose)
        }

      case "exit":
        os.Exit(0)

    }

  }

}
