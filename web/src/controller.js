// Use protocol buffers.
require("./infovis.proto3_pb")


// Set up the document.
function startup() {

  var gl = glCanvas.getContext("webgl")

  gl.canvas.width  = window.innerWidth
  gl.canvas.height = window.innerHeight

  gl.clearColor(0.0, 0.0, 0.0, 1.0);
  gl.clear(gl.COLOR_BUFFER_BIT);

}


function connect(url, handler) {
  var connection = new WebSocket(url)
  connection.binaryType = "arraybuffer"
  handlers = new Object()
  connection.onmessage =
    function(event) {
      var buffer = new Uint8Array(event.data);
      var request = proto.Infovis.Request.deserializeBinary(buffer)
      handler(connection, request)
    }
  return connection
}


function disconnect(connection) {
  connection.close(1000, "normal termination");
}


function echoHandler(connection, request) {
  console.log("Request: ", request)
}


// Export functions.
module.exports = {
  startup     : startup
, connect     : connect
, disconnect  : disconnect
, echoHandler : echoHandler
}
