package infovis


import (
  "io/ioutil"
  "path/filepath"
  "sync"
  "github.com/golang/glog"
)


type Files struct {
  label     Label
  channel   ProtobufChannel
  filenames []string
  filename  chan string
  done      DoneChannel
  mux       sync.RWMutex
}


func NewFiles(label Label, filenames []string, reaper LabelInChannel) *Files {

  var files = Files{
    label    : label                ,
    channel  : make(ProtobufChannel),
    filenames: unglob(filenames)    ,
    filename : make(chan string)    ,
    done     : make(DoneChannel)    ,
  }

  go func() {
    <-files.done
    reaper <- files.label
  }()

  go func() {
    defer glog.Infof("Files source %s is closing.\n", files.label)
    defer close(files.channel)
    defer close(files.filename)
    for {
      select {
        case file := <-files.filename:
          glog.Infof("Files source %s is reading file %s.\n", files.label, file)
          buffer, err := ioutil.ReadFile(file)
          if err != nil {
            glog.Warningf("Files source %s encountered %v.\n", files.label, err)
            break
          }
          select {
            case files.channel <- buffer:
              glog.Infof("Files source %s sent %v bytes.\n", files.label, len(buffer))
            case <-files.done:
              return
          }
        case <-files.done:
          return
      }
    }
  }()

  files.Reset()

  return &files

}


func (files *Files) Append(filenames []string) {
  filenames1 := unglob(filenames)
  files.mux.Lock()
  files.filenames = append(files.filenames, filenames1...)
  files.mux.Unlock()
  go func() {
    for _, file := range filenames1 {
      select {
        case files.filename <- file:
        case <-files.done:
          return
      }
    }
  }()
}


func (files *Files) Label() Label {
  return files.label
}


func (files *Files) Out() ProtobufOutChannel {
  return files.channel
}


func (files *Files) Reset() {
  files.mux.RLock()
  filenames1 := files.filenames
  files.mux.RUnlock()
  go func() {
    for _, file := range filenames1 {
      select {
        case files.filename <- file:
        case <-files.done:
          return
      }
    }
  }()
}


func (files *Files) Exit() {
  select {
    case <-files.done:
    default:
      close(files.done)
  }
}


func (files *Files) Alive() bool {
  select {
    case <-files.done:
      return false
    default:
      return true
  }
}


func unglob(filenames []string) []string {
  var result []string
  for _, filename := range filenames {
    matches, err := filepath.Glob(filename)
    if err != nil {
      glog.Warningf("Invalid glob pattern '%s': %v.\n", filename, err)
      continue
    }
    if len(matches) == 0 {
      glog.Warningf("Glob pattern '%s' matched no files.\n", filename)
    }
    result = append(result, matches...)
  }
  return result
}
