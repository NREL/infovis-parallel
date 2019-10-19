
const Configuration = require("./configuration")
const Connection    = require("./connection"   )

const Rendering = {
  Buffers : require("./rendering/buffers")
, Program : require("./rendering/program")
, Shapes  : require("./rendering/shapes" )
}


function echoHandler(connection, request) {
  console.log("Request: ", request)
  window.request = request
}


var theContext = null


// Set up the document.
function startup() {

  theContexr = uiCanvas.getContext("webgl2")
  gl = theContext

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
, Rendering     : Rendering
, context       : () => theContext
, handler       : echoHandler
, startup       : startup
}
