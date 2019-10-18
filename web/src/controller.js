// Use protocol buffers.
require("./infovis.proto3_pb")


function connect(url, handler, closer) {
  var connection = new WebSocket(url)
  connection.binaryType = "arraybuffer"
  handlers = new Object()
  connection.onmessage =
    function(event) {
      var buffer = new Uint8Array(event.data);
      var request = proto.Infovis.Request.deserializeBinary(buffer)
      handler(connection, request)
    }
  connection.onclose = closer
  return connection
}


function disconnect(connection) {
  connection.close(1000, "normal termination");
}


function echoHandler(connection, request) {
  console.log("Request: ", request)
  window.request = request
}


var cxn = null


function updateConnectButtons() {
  connector.style.visibility = cxn == null ? "visible" : "hidden"
  visualize.style.visibility = cxn != null ? "visible" : "hidden"
}

function disconnected() {
  console.log("Disconnected")
  cxn = null
  updateConnectButtons()
}

function reconnect() {
  var url = connection.value
  console.log("Connect:", url)
  cxn = connect(url, echoHandler, disconnected)
  updateConnectButtons()
}

function unconnect() {
  console.log("Disconnect")
  disconnect(cxn)
  cxn = null
  updateConnectButtons()
}


// Set up the document.
function startup() {

  var gl = glCanvas.getContext("webgl")

  gl.canvas.width  = window.innerWidth
  gl.canvas.height = window.innerHeight

  gl.clearColor(0.0, 0.0, 0.0, 1.0);
  gl.clear(gl.COLOR_BUFFER_BIT);

  updateConnectButtons()
}

// Export functions.
module.exports = {
  startup   : startup
, reconnect : reconnect
, unconnect : unconnect
}
