package infovis


import (
  "bufio"
  "log"
  "os"
  "regexp"
  "strings"
)


func checkArguments(tokens []string, message string, count int, exact bool) bool {
  if exact && len(tokens) != count || len(tokens) < count {
    log.Println(message)
    return false
  } else {
    return true
  }
}


func lookupSource(sources map[Label]Source, label Label) (Source, bool) {
  source, ok := sources[label]
  if !ok {
    log.Println("The source", label, "does not exist.")
    return nil, false
  } else {
    return source, true
  }
}


func lookupSink(sinks map[Label]Sink, label Label) (Sink, bool) {
  sink, ok := sinks[label]
  if !ok {
    log.Println("The sink", label, "does not exist.")
    return nil, false
  } else {
    return sink, true
  }
}


func Main() {

  log.SetPrefix("InfoVis: ")

  var sources = make(map[Label]Source)
  var sinks   = make(map[Label]Sink  )

  var reader = bufio.NewReader(os.Stdin)

  var tokenizer = regexp.MustCompile(" +")

  for {

    line, _ := reader.ReadString('\n')
    tokens := tokenizer.Split(strings.TrimSuffix(line, "\n"), -1)

    switch tokens[0] {

      case "absorber":
        if checkArguments(tokens, "The 'absorber' command must name a channel.", 2, true) {
          sinks[tokens[1]] = NewAbsorber(tokens[1])
        }

      case "printer":
        if checkArguments(tokens, "The 'printer' command must name a channel.", 2, true) {
          sinks[tokens[1]] = NewPrinter(tokens[1])
        }

      case "files":
        if checkArguments(tokens, "The 'files' command must name a channel.", 2, false) {
          sources[tokens[1]] = NewFiles(tokens[1], tokens[2:])
        }

      case "relay":
        if checkArguments(tokens, "The 'relay' command must have a source and a sink.", 3, true) {
          if source, ok := lookupSource(sources, tokens[1]); ok {
            if sink, ok := lookupSink(sinks, tokens[2]); ok {
              go Relay(source, sink)
            }
          }
        }

      case "exit":
        os.Exit(0)

    }

  }

}
