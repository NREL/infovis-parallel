// Use protocol buffers.
require("./infovis.proto3_pb")

const Configuration = require("./configuration"    )


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


var theConnection = null


function updateConnectButtons() {
  uiConnector.style.visibility = theConnection == null ? "visible" : "hidden"
  uiVisualize.style.visibility = theConnection != null ? "visible" : "hidden"
}

function disconnected() {
  console.log("Disconnected")
  theConnection = null
  updateConnectButtons()
}

function reconnect() {
  configuration = Configuration.update()
  var url = configuration.server.address
  console.log("Connect:", url)
  theConnection = connect(url, echoHandler, disconnected)
  updateConnectButtons()
}

function unconnect() {
  console.log("Disconnect")
  disconnect(theConnection)
  theConnection = null
  updateConnectButtons()
}


// Set up the document.
function startup() {

  var gl = uiCanvas.getContext("webgl")

  gl.canvas.width  = window.innerWidth
  gl.canvas.height = window.innerHeight

  gl.clearColor(0.0, 0.0, 0.0, 1.0);
  gl.clear(gl.COLOR_BUFFER_BIT);

  Configuration.reset()
  updateConnectButtons()
}

// Export functions.
module.exports = {
  Configuration : Configuration
, startup       : startup
, reconnect     : reconnect
, unconnect     : unconnect
}
