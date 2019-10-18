const Configuration = require("./configuration")
const WebSocket     = require("./websocket"    )


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
  theConnection = WebSocket.connect(url, echoHandler, disconnected)
  updateConnectButtons()
}

function unconnect() {
  console.log("Disconnect")
  WebSocket.disconnect(theConnection)
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
, WebSocket     : WebSocket
, reconnect     : reconnect
, startup       : startup
, unconnect     : unconnect
}
