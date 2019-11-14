
require("./google-protobuf.js"  )
require("./infovis.proto3_pb.js")


const DEBUG = false


const noSending = true


const statename = {
  0 : "connecting"
, 1 : "open"
, 2 : "closing"
, 3 : "closed"
}


export function connect(url, handler, closer) {

  const connection = new WebSocket(url)

  connection.binaryType = "arraybuffer"

  connection.onerror = function(event) {
    if (DEBUG) console.debug("WebSocket.onerror =", event)
    if (connection.readyState != 3)
      window.alert("WebSocket error (state = \"" + statename[connection.readyState] + "\").")
  }

  connection.onclose = function(event) {
    if (!event.wasClean)
      window.alert("WebSocket connection is lost.")
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


export function disconnect(connection) {
  connection.close(1000, "normal termination")
  connection.onmessage = null
  connection.onclose   = null
  connection.onerror   = null
}


export function send(connection, response) {
  if (DEBUG) {
    console.debug("WebSocket.send: response =", response)
  if (!noSending)
    window.theResponse = response
  }
  connection.send(response.serializeBinary())
}
