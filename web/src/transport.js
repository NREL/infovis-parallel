
'use strict';


require("./infovis.proto3_pb")


const DEBUG = false


const noSending = true


function connect(url, handler, closer) {
  const connection = new WebSocket(url)
  connection.binaryType = "arraybuffer"
  connection.onmessage =
    function(event) {
      const buffer = new Uint8Array(event.data)
      const request = proto.Infovis.Request.deserializeBinary(buffer)
      if (DEBUG) {
        console.debug("receive: request =", buffer)
        window.theRequest = request
      }
      handler(connection, request)
    }
  connection.onclose = closer
  return connection
}


function disconnect(connection) {
  connection.close(1000, "normal termination")
}


function send(connection, response) {
  if (DEBUG) {
    console.debug("send: response =", response)
  if (!noSending)
    window.theResponse = response
  }
  connection.send(response.serializeBinary())
}


module.exports = {
  connect    : connect
, disconnect : disconnect
, send       : send
}
