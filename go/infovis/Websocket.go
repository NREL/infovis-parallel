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
  var server = Server {
    root      : root                      ,
    websockets: make(map[Label]*Websocket),
    verbose   : verbose                   ,
  }
  http.HandleFunc(root, server.makeHandler())
  go func() {
    if verbose {
      log.Printf("Serving WebSockets on address %s%s.\n", address, server.root)
    }
    log.Fatal(http.ListenAndServe(address, nil))
  }()
  return &server
}


func (server *Server) makeHandler() func(http.ResponseWriter, *http.Request) {
  return func (responseWriter http.ResponseWriter, request *http.Request) {

    conn, err := upgrader.Upgrade(responseWriter, request, nil)
    if err != nil {
      log.Fatal(err)
    }
    defer conn.Close()

    if !strings.HasPrefix(request.URL.Path, server.root) {
      log.Printf("Invalid WebSocket path %s\n.", request.URL.Path)
      return
    }

    label := strings.TrimPrefix(request.URL.Path, server.root)
    server.mux.Lock()
    websocket, found := server.websockets[label]
    server.mux.Unlock()
    if !found {
      if server.verbose {
        log.Printf("No WebSocket for %s.\n", label)
      }
      return
    }
    if server.verbose {
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

  var socket = Websocket {
    label  : label                  ,
    in     : make(ProtobufChannel)  ,
    out    : make(ProtobufChannel)  ,
    exit   : false                  ,
    verbose: verbose                ,
    server : server                 ,
  }

  server.mux.Lock()
  server.websockets[label] = &socket
  server.mux.Unlock()

  go func() {
    for !socket.exit {
      buffer := <-socket.in
      socket.mux.Lock()
      conns := socket.conns
      socket.mux.Unlock()
      for _, conn := range conns {
        err := conn.WriteMessage(websocket.BinaryMessage, buffer)
        if err != nil {
          log.Printf("Removing Websocket connection for %s.\n", label)
          socket.removeConnection(conn)
          continue
        }
      }
    }
    if verbose {
      log.Printf("WebSocket %s is closing.\n", label)
    }
    close(socket.in)
    close(socket.out)
  }()

  return &socket

}


func (socket *Websocket) addConnection(conn *websocket.Conn) {
  socket.mux.Lock()
  socket.conns = append(socket.conns, conn)
  socket.mux.Unlock()
}


func (socket *Websocket) removeConnection(conn *websocket.Conn) {
  socket.mux.Lock()
  for i, conn1 := range socket.conns {
    if conn == conn1 {
      socket.conns = append(socket.conns[:i], socket.conns[i+1:]...)
      break
    }
  }
  socket.mux.Unlock()
}


func (socket *Websocket) received(buffer *[]byte) {
  socket.out <- *buffer
}


func (socket *Websocket) Label() Label {
  return socket.label
}


func (socket *Websocket) In() *ProtobufChannel {
  return &socket.in
}


func (socket *Websocket) Out() *ProtobufChannel {
  return &socket.out
}


func (socket *Websocket) Append(arguments []string) {
}


func (socket *Websocket) Reset() {
}


func (socket *Websocket) Exit() {
  socket.exit = true
}


func (socket *Websocket) Alive() bool {
  return !socket.exit
}
