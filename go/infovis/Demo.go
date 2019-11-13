package infovis

import (
  "io/ioutil"
  "log"
  "net/http"
  "path/filepath"
  "github.com/gorilla/websocket"
)


func Demo(address string, path string, globs []string) {

  var upgrader = websocket.Upgrader{
    ReadBufferSize : 16384                                   ,
    WriteBufferSize: 16384                                   ,
    CheckOrigin    : func(r *http.Request) bool {return true},
  }

  var handler = func(responseWriter http.ResponseWriter, request *http.Request) {

    conn, err := upgrader.Upgrade(responseWriter, request, nil)
    if err != nil {
      log.Fatal(err)
      return
    }
    defer conn.Close()

    for _, glob := range globs {
      matches, err := filepath.Glob(glob)
      if err != nil {
        log.Fatal(err)
        continue
      }
      for _, filename := range matches {
        buffer, err := ioutil.ReadFile(filename)
        if err != nil {
          log.Fatal(err)
          return
        }
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
  log.Fatal(http.ListenAndServe(address, nil))

}
