
'use strict';


require("./infovis.proto3_pb")


const DEBUG = false


const noSending = true


const statename = {
  0 : "connecting"
, 1 : "open"
, 2 : "closing"
, 3 : "closed"
}


function connect(url, handler, closer) {

  const connection = new WebSocket(url)

  connection.binaryType = "arraybuffer"

  connection.onerror = function(event) {
    if (DEBUG) console.debug("WebSocket.onerror =", event)
    window.alert("WebSocket error (state = \"" + statename[connection.readyState] + "\").")
  }

  connection.onclose = function(event) {
    if (!event.wasClean)
      window.alert("WebSocket connection lost.")
    closer()
  }

  connection.onmessage = function(event) {
      const buffer = new Uint8Array(event.data)
      const request = proto.Infovis.Request.deserializeBinary(buffer)
      if (DEBUG) {
        console.debug("WebSocket.onmessage: request =", buffer)
        window.theRequest = request
      }
      handler(connection, request)
    }

  return connection
}


function disconnect(connection) {
  connection.close(1000, "normal termination")
}


function send(connection, response) {
  if (DEBUG) {
    console.debug("WebSocket.send: response =", response)
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
