package infovis


import (
  "io/ioutil"
  "path/filepath"
  "sync"
  "github.com/golang/glog"
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


func NewFiles(label Label, filenames []string) *Files {

  filenames1 := unglob(filenames)

  var files = Files{
    label    : label                ,
    channel  : make(ProtobufChannel),
    filenames: filenames1           ,
    index    : 0                    ,
    exit     : false                ,
    wake     : make(chan struct{})  ,
  }

  go func() {
    for !files.exit {
      <-files.wake
      glog.Infof("Files source %s has awoken.\n", files.label)
      files.mux.Lock()
      for (files.index < len(files.filenames)) {
        filename := files.filenames[files.index]
        files.index++
        glog.Infof("Files source %s is reading file %s.\n", files.label, filename)
        buffer, err := ioutil.ReadFile(filename)
        if err != nil {
          glog.Errorf("Files source %s encountered %v.\n", files.label, err)
          continue
        }
        files.channel <- buffer
        glog.Infof("Files source %s sent %v bytes.\n", files.label, len(buffer))
      }
      files.mux.Unlock()
    }
    glog.Infof("Files source %s is closing.\n", files.label)
    close(files.channel)
  }()

  files.wake <- empty

  return &files

}


func (files *Files) Append(filenames []string) {
  filenames1 := unglob(filenames)
  files.mux.Lock()
  files.filenames = append(files.filenames, filenames1...)
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


func unglob(filenames []string) []string {
  var result []string
  for _, filename := range filenames {
    matches, err := filepath.Glob(filename)
    if err != nil {
      glog.Errorf("Invalid glob pattern '%s': %v.", filename, err)
      continue
    }
    result = append(result, matches...)
  }
  return result
}
