package infovis


import (
  "log"
  "net/http"
  "strings"
  "sync"
  "github.com/gorilla/websocket"
)


type Server struct {
  root       string
  websockets map[Label]*Websocket
  mux        sync.Mutex
  verbose    bool
}


var upgrader = websocket.Upgrader{
  ReadBufferSize : 16384                                         ,
  WriteBufferSize: 16384                                         ,
  CheckOrigin    : func(request *http.Request) bool {return true},
}


func NewServer(address string, root string, verbose bool) *Server {
  var this = Server {
    root      : root                      ,
    websockets: make(map[Label]*Websocket),
    verbose   : verbose                   ,
  }
  http.HandleFunc(root, this.makeHandler())
  go func() {
    if verbose {
      log.Printf("Serving WebSockets on address %s%s.\n", address, this.root)
    }
    log.Fatal(http.ListenAndServe(address, nil))
  }()
  return &this
}


func (this *Server) makeHandler() func(http.ResponseWriter, *http.Request) {
  return func (responseWriter http.ResponseWriter, request *http.Request) {

    conn, err := upgrader.Upgrade(responseWriter, request, nil)
    if err != nil {
      log.Fatal(err)
    }
    defer conn.Close()

    if !strings.HasPrefix(request.URL.Path, this.root) {
      log.Printf("Invalid WebSocket path %s\n.", request.URL.Path)
      return
    }

    label := strings.TrimPrefix(request.URL.Path, this.root)
    this.mux.Lock()
    websocket, found := this.websockets[label]
    this.mux.Unlock()
    if !found {
      if this.verbose {
        log.Printf("No WebSocket for %s.\n", label)
      }
      return
    }
    if this.verbose {
      log.Printf("WebSocket established for %s.\n", label)
    }

    websocket.addConnection(conn)

    for !websocket.exit {
      _, buffer, err := conn.ReadMessage()
      if err != nil {
        log.Printf("WebSocket %s encountered %v.\n", label, err)
        break
      }
      websocket.received(&buffer)
    }

    websocket.removeConnection(conn)

  }
}


type Websocket struct {
  label   Label
  in      ProtobufChannel
  out     ProtobufChannel
  exit    bool
  verbose bool
  server  *Server
  conns   []*websocket.Conn
  mux     sync.Mutex
}


func NewWebsocket(server *Server, label Label, verbose bool) *Websocket {

  var this = Websocket {
    label  : label                  ,
    in     : make(ProtobufChannel)  ,
    out    : make(ProtobufChannel)  ,
    exit   : false                  ,
    verbose: verbose                ,
    server : server                 ,
  }

  server.mux.Lock()
  server.websockets[label] = &this
  server.mux.Unlock()

  go func() {
    for !this.exit {
      buffer := <-this.in
      this.mux.Lock()
      conns := this.conns
      this.mux.Unlock()
      for _, conn := range conns {
        err := conn.WriteMessage(websocket.BinaryMessage, buffer)
        if err != nil {
          log.Printf("Removing Websocket connection for %s.\n", label)
          this.removeConnection(conn)
          continue
        }
      }
    }
    if verbose {
      log.Printf("WebSocket %s is closing.\n", label)
    }
    close(this.in)
    close(this.out)
  }()

  return &this

}


func (this *Websocket) addConnection(conn *websocket.Conn) {
  this.mux.Lock()
  this.conns = append(this.conns, conn)
  this.mux.Unlock()
}


func (this *Websocket) removeConnection(conn *websocket.Conn) {
  this.mux.Lock()
  for i, conn1 := range this.conns {
    if conn == conn1 {
      this.conns = append(this.conns[:i], this.conns[i+1:]...)
      break
    }
  }
  this.mux.Unlock()
}


func (this *Websocket) received(buffer *[]byte) {
  this.out <- *buffer
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
