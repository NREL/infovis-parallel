package infovis


import (
  "io/ioutil"
  "log"
  "sync"
)


type Files struct {
  label   Label
  channel ProtobufChannel
  files   []string
  index   int
  exit    bool
  mux     sync.Mutex
  wake    chan bool
}


func NewFiles(label Label, files []string, verbose bool) *Files {

  var this = Files{
    label  : label                 ,
    channel: make(ProtobufChannel) ,
    files  : files                 ,
    index  : 0                     ,
    exit   : false                 ,
    wake   : make(chan bool)       ,
  }

  go func() {
    for !this.exit {
      <-this.wake
      this.mux.Lock() // FIXME: Lock mutex for a shorter time.
      for (this.index < len(this.files)) {
        file := this.files[this.index]
        this.index += 1
        if verbose {
          log.Printf("Files source %s is reading file %s.\n", this.label, file)
        }
        buffer, err := ioutil.ReadFile(file)
        if err != nil {
          log.Printf("Files source %s encountered %v.\n", this.label, err)
          this.exit = true
          break
        }
        this.channel <- buffer
        if verbose {
          log.Printf("Files source %s send %v bytes.\n", this.label, len(buffer))
        }
      }
      this.mux.Unlock()
    }
    if verbose {
      log.Printf("Files source %s is closing.\n", this.label)
    }
    close(this.channel)
  }()

  this.wake <- true

  return &this

}


func (this *Files) Append(files []string) {
  this.mux.Lock()
  this.files = append(this.files, files...)
  this.mux.Unlock()
  this.wake <- true
}


func (this *Files) Label() Label {
  return this.label
}


func (this *Files) Out() *ProtobufChannel {
  return &this.channel
}


func (this *Files) Reset() {
  this.mux.Lock()
  this.index = 0
  this.mux.Unlock()
  this.wake <- true
}


func (this *Files) Exit() {
  this.exit = true
}


func (this *Files) Alive() bool {
  return !this.exit
}
