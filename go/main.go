package main

import (

  "fmt"
  "io/ioutil"
  "log"
  "net/http"
  "os"

  "github.com/gorilla/websocket"

)


var upgrader = websocket.Upgrader{
  ReadBufferSize : 8192                                    ,
  WriteBufferSize: 8192                                    ,
  CheckOrigin    : func(r *http.Request) bool {return true},
}


var filenames []string = nil


func handler(hw http.ResponseWriter, hr *http.Request) {

  conn, err := upgrader.Upgrade(hw, hr, nil)
  if err != nil {
    log.Fatal(err)
    return
  }
  defer conn.Close()

  for _, filename := range filenames {
    fmt.Println(filename)
    buffer, err := ioutil.ReadFile(filename)
    if err != nil {
      log.Fatal(err)
      return
    }
    conn.WriteMessage(websocket.BinaryMessage, buffer)
  }

  for {
    _, _, err := conn.ReadMessage()
    if err != nil {
      log.Fatal(err)
      return
    }
  }

}


func main() {
  filenames = os.Args[1:]
  http.HandleFunc("/", handler)
  log.Fatal(http.ListenAndServe("127.0.0.1:42042", nil))
}
