package infovis


import (
  "io/ioutil"
  "log"
  "sync"
)


var empty struct{}


type Files struct {
  label     Label
  channel   ProtobufChannel
  filenames []string
  index     int
  exit      bool
  mux       sync.Mutex
  wake      chan struct{}
}


func NewFiles(label Label, filenames []string, verbose bool) *Files {

  var files = Files{
    label    : label                 ,
    channel  : make(ProtobufChannel) ,
    filenames: filenames                 ,
    index    : 0                     ,
    exit     : false                 ,
    wake     : make(chan struct{})   ,
  }

  go func() {
    for !files.exit {
      <-files.wake
      if verbose {
        log.Printf("Files source %s has awoken.\n", files.label)
      }
      files.mux.Lock()
      for (files.index < len(files.filenames)) {
        filename := files.filenames[files.index]
        files.index++
        if verbose {
          log.Printf("Files source %s is reading file %s.\n", files.label, filename)
        }
        buffer, err := ioutil.ReadFile(filename)
        if err != nil {
          log.Printf("Files source %s encountered %v.\n", files.label, err)
          continue
        }
        files.channel <- buffer
        if verbose {
          log.Printf("Files source %s sent %v bytes.\n", files.label, len(buffer))
        }
      }
      files.mux.Unlock()
    }
    if verbose {
      log.Printf("Files source %s is closing.\n", files.label)
    }
    close(files.channel)
  }()

  files.wake <- empty

  return &files

}


func (files *Files) Append(filenames []string) {
  files.mux.Lock()
  files.filenames = append(files.filenames, filenames...)
  files.mux.Unlock()
  files.wake <- empty
}


func (files *Files) Label() Label {
  return files.label
}


func (files *Files) Out() *ProtobufChannel {
  return &files.channel
}


func (files *Files) Reset() {
  files.mux.Lock()
  files.index = 0
  files.mux.Unlock()
  files.wake <- empty
}


func (files *Files) Exit() {
  files.exit = true
}


func (files *Files) Alive() bool {
  return !files.exit
}
