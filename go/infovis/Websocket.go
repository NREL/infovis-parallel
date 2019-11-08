package infovis


import (
  "log"
  "net/http"
  "github.com/gorilla/websocket"
)


type Server struct {
  verbose bool
}


var upgrader = websocket.Upgrader{
  ReadBufferSize : 8192                                          ,
  WriteBufferSize: 8192                                          ,
  CheckOrigin    : func(request *http.Request) bool {return true},
}


func handler(responseWriter http.ResponseWriter, request *http.Request) {

  conn, err := upgrader.Upgrade(responseWriter, request, nil)
  if err != nil {
    log.Fatal(err)
  }
  defer conn.Close()

  for {
    _, _, err := conn.ReadMessage()
    if err != nil {
      log.Fatal(err)
      return
    }
  }

}


const root = "/infovis/v2/"


func NewServer(address string, verbose bool) *Server {
  var this = Server {
    verbose: verbose,
  }
  http.HandleFunc(root, handler)
  go func() {
    if verbose {
      log.Printf("Serving WebSockets on address %s.", address)
    }
    log.Fatal(http.ListenAndServe(address, nil))
  }()
  return &this
}


type Websocket struct {
  label   Label
  in      ProtobufChannel
  out     ProtobufChannel
  exit    bool
  verbose bool
}


func NewWebsocket(server *Server, label Label, verbose bool) *Websocket {
  var this = Websocket {
    label  : label                ,
    in     : make(ProtobufChannel),
    out    : make(ProtobufChannel),
    exit   : false                ,
    verbose: verbose              ,
  }
  return &this
}


func (this *Websocket) Label() Label {
  return this.label
}


func (this *Websocket) In() *ProtobufChannel {
  return &this.in
}


func (this *Websocket) Out() *ProtobufChannel {
  return &this.out
}


func (this *Websocket) Append(arguments []string) {
}


func (this *Websocket) Reset() {
}


func (this *Websocket) Exit() {
  this.exit = true
}


func (this *Websocket) Alive() bool {
  return !this.exit
}
