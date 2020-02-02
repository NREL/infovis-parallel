package infovis

import (
  "io/ioutil"
  "net/http"
  "path/filepath"
  "github.com/golang/glog"
  "github.com/gorilla/websocket"
)


func Demo(address string, path string, globs []string) {

  var upgrader = websocket.Upgrader{
    ReadBufferSize : 16384                                         ,
    WriteBufferSize: 16384                                         ,
    CheckOrigin    : func(request *http.Request) bool {return true},
  }

  var handler = func(responseWriter http.ResponseWriter, request *http.Request) {

    conn, err := upgrader.Upgrade(responseWriter, request, nil)
    if err != nil {
      glog.Fatal(err)
    }
    defer conn.Close()
    glog.Warningf("Handling request from %s.\n", request.RemoteAddr)

    for _, glob := range globs {
      matches, err := filepath.Glob(glob)
      if err != nil {
        glog.Fatal(err)
      }
      for _, filename := range matches {
        buffer, err := ioutil.ReadFile(filename)
        if err != nil {
          glog.Fatal(err)
          return
        }
        glog.Infof("Sending file %s.\n", filename)
        conn.WriteMessage(websocket.BinaryMessage, buffer)
      }
    }

    for {
      _, _, err := conn.ReadMessage()
      if err != nil {
        return
      }
    }

  }


  http.HandleFunc(path, handler)
  glog.Fatal(http.ListenAndServe(address, nil))

}
