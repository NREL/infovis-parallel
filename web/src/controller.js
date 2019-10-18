
const Configuration = require("./configuration")
const Connection    = require("./connection"   )

const Rendering = {
  Program : require("./rendering/program")
}


function echoHandler(connection, request) {
  console.log("Request: ", request)
  window.request = request
}


// Set up the document.
function startup() {

  var gl = uiCanvas.getContext("webgl")

  gl.canvas.width  = window.innerWidth
  gl.canvas.height = window.innerHeight

  gl.clearColor(0.0, 0.0, 0.0, 1.0);
  gl.clear(gl.COLOR_BUFFER_BIT);

  Configuration.reset()
  Connection.updateButtons()
}

// Export functions.
module.exports = {
  Configuration : Configuration
, Connection    : Connection
, handler       : echoHandler
, startup       : startup
}
