package infovis


import (
  "net/http"
  "strings"
  "sync"
  "github.com/golang/glog"
  "github.com/gorilla/websocket"
)


type Server struct {
  root       string
  websockets map[Label]*Websocket
  mux        sync.Mutex
}


var upgrader = websocket.Upgrader{
  ReadBufferSize : 16384                                         ,
  WriteBufferSize: 16384                                         ,
  CheckOrigin    : func(request *http.Request) bool {return true},
}


func NewServer(address string, root string) *Server {
  var server = Server {
    root      : root                      ,
    websockets: make(map[Label]*Websocket),
  }
  http.HandleFunc(root, server.makeHandler())
  go func() {
    glog.Infof("Serving WebSockets on address %s%s.\n", address, server.root)
    glog.Fatal(http.ListenAndServe(address, nil))
  }()
  return &server
}


func (server *Server) makeHandler() func(http.ResponseWriter, *http.Request) {
  return func (responseWriter http.ResponseWriter, request *http.Request) {

    conn, err := upgrader.Upgrade(responseWriter, request, nil)
    if err != nil {
      glog.Fatal(err)
    }
    defer conn.Close()

    if !strings.HasPrefix(request.URL.Path, server.root) {
      glog.Errorf("Invalid WebSocket path %s\n.", request.URL.Path)
      return
    }

    label := strings.TrimPrefix(request.URL.Path, server.root)
    server.mux.Lock()
    websocket, found := server.websockets[label]
    server.mux.Unlock()
    if !found {
      glog.Infof("No WebSocket for %s.\n", label)
      return
    }
    glog.Infof("WebSocket established for %s.\n", label)

    websocket.addConnection(conn)

    for websocket.Alive() {
      _, buffer, err := conn.ReadMessage()
      if err != nil {
        glog.Errorf("WebSocket %s encountered %v.\n", label, err)
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
  done    DoneChannel
  server  *Server
  conns   []*websocket.Conn
  mux     sync.Mutex
}


func NewWebsocket(server *Server, label Label) *Websocket {

  var socket = Websocket {
    label  : label                ,
    in     : make(ProtobufChannel),
    out    : make(ProtobufChannel),
    done   : make(DoneChannel)    ,
    server : server               ,
  }

  server.mux.Lock()
  server.websockets[label] = &socket
  server.mux.Unlock()

  go func() {
    defer glog.Infof("WebSocket %s is closing.\n", label)
    defer close(socket.in)
    defer close(socket.out)
    for {
      select {
        case buffer := <-socket.in:
          socket.mux.Lock()
          conns := socket.conns
          socket.mux.Unlock()
          for _, conn := range conns {
            err := conn.WriteMessage(websocket.BinaryMessage, buffer)
            if err != nil {
              glog.Errorf("Removing Websocket connection for %s.\n", label)
              socket.removeConnection(conn)
              continue
            }
          }
        case <-socket.done:
          return
      }
    }
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


func (socket *Websocket) Reset() {
}


func (socket *Websocket) Exit() {
  close(socket.done)
}


func (socket *Websocket) Alive() bool {
  select {
    case <-socket.done:
      return false
    default:
      return true
  }
}
