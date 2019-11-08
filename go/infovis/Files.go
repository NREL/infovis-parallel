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
}


func NewFiles(label Label, files []string) *Files {

  var this = Files{
    label  : label                ,
    channel: make(ProtobufChannel),
    files  : files                ,
    index  : 0                    ,
    exit   : false                ,
  }

  go func() {
    for {
      // FIXME: Lock mutex for a shorter time.
      this.mux.Lock()
      if this.exit {
        this.mux.Unlock()
        close(this.channel)
        return
      }
      for (this.index < len(this.files)) {
        file := this.files[this.index]
        this.index += 1
        buffer, err := ioutil.ReadFile(file)
        log.Println("Files source", this.label, "read", file, ".")
        if err != nil {
          log.Println("Fiels source", this.label, "encountered", err, ".")
          this.exit = true
          break
        }
        this.channel <- buffer
        log.Println("Files source", this.label, "sent", len(buffer), "bytes.")
      }
      this.mux.Unlock()
    }
  }()

  return &this

}


func (this *Files) Append(files []string) {
  this.mux.Lock()
  this.files = append(this.files, files...)
  this.mux.Unlock()
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
}


func (this *Files) Exit() {
  this.mux.Lock()
  this.exit = true
  this.mux.Unlock()
}
