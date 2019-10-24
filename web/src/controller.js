
const Configuration = require("./configuration")
const Connection    = require("./connection"   )
const Visualizer    = require("./visualizer"   )


function echoHandler(connection, request) {
  console.log("Echo request: ", request)
  window.lastRequest = request
}


var theContext = null


// Set up the document.
function startup() {

  theContext = uiCanvas.getContext("webgl2")
  const gl = theContext

  gl.canvas.width  = window.innerWidth
  gl.canvas.height = window.innerHeight

  Visualizer.setup(gl)

  Configuration.reset()
  Connection.updateButtons()
}


function startVisualizing() {
  const configuration = Configuration.update()
  Connection.reconnect(configuration, echoHandler)
  Visualizer.visualizeBuffers(theContext, configuration)
}


function stopVisualizing() {
  Connection.unconnect()
}


// Export functions.
module.exports = {
  Configuration    : Configuration
, startVisualizing : startVisualizing
, startup          : startup
, stopVisualizing  : stopVisualizing
}
