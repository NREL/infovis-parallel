package infovis


import (
  "io/ioutil"
  "fmt"
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


func NewFiles(label Label, files []string, verbose bool) *Files {

  var this = Files{
    label  : label                ,
    channel: make(ProtobufChannel),
    files  : files                ,
    index  : 0                    ,
    exit   : false                ,
  }

  go func() {
    for !this.exit {
      this.mux.Lock() // FIXME: Lock mutex for a shorter time.
      for (this.index < len(this.files)) {
        file := this.files[this.index]
        this.index += 1
        if verbose {
          fmt.Println("Files source", this.label, "reading", file, ".")
        }
        buffer, err := ioutil.ReadFile(file)
        if err != nil {
          fmt.Println("Files source", this.label, "encountered", err, ".")
          this.exit = true
          break
        }
        this.channel <- buffer
        if verbose {
          fmt.Println("Files source", this.label, "sent", len(buffer), "bytes.")
        }
      }
      this.mux.Unlock()
    }
    if verbose {
      fmt.Println("Files source", this.label, "closed.")
    }
    close(this.channel)
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
  this.exit = true
}


func (this *Files) Alive() bool {
  return !this.exit
}
