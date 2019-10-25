
const Configuration = require("./configuration")
const Connection    = require("./connection"   )
const Visualizer    = require("./visualizer"   )


const requestQueue = []


function echoHandler(connection, request) {
  requestQueue.unshift(request)
  window.lastRequest = request
}


let theContext = null


// Set up the document.
function startup() {

  theContext = uiCanvas.getContext("webgl2")
  const gl = theContext

  gl.canvas.width  = window.innerWidth
  gl.canvas.height = window.innerHeight

  Visualizer.setupCanvas(gl)

  Configuration.reset()
  Connection.updateButtons()
}


function startVisualizing() {
  const configuration = Configuration.update()
  Connection.reconnect(configuration, echoHandler)
  Visualizer.visualizeBuffers(theContext, configuration, requestQueue)
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
