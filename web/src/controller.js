
'use strict';


const Configuration = require("./configuration")
const Connection    = require("./connection"   )
const Visualizer    = require("./visualizer"   )


const requestQueue = []

const keyQueue = []

let isVisualizing = false

let theContext = null


function echoHandler(connection, request) {
  requestQueue.unshift(request)
}


function disconnectHandler() {
  stopVisualizing()
}


function keyHandler(event) {
  if (!isVisualizing || event.defaultPrevented)
    return
  keyQueue.unshift({
    key  : event.key || event.keyCode
  , shift: event.shiftKey
  })
}


function startup() {

  document.addEventListener("keydown", keyHandler)

  theContext = uiCanvas.getContext("webgl2")
  const gl = theContext

  gl.canvas.width  = window.innerWidth
  gl.canvas.height = window.innerHeight

  Visualizer.setupCanvas(gl)

  Configuration.compute()
  Connection.updateButtons()

}


function startVisualizing() {
  const configuration = Configuration.update()
  Connection.reconnect(configuration, echoHandler, disconnectHandler)
  isVisualizing = true
  Visualizer.visualizeBuffers(theContext, configuration, requestQueue, keyQueue, Connection.send)
}


function stopVisualizing() {
  Connection.unconnect()
  Visualizer.stop()
  isVisualizing = false
}


function toggleHelp() {
  uiKeyboard.style.visibility = uiKeyboard.style.visibility == "visible" ? "hidden" : "visible"
}


module.exports = {
  Configuration    : Configuration
, startVisualizing : startVisualizing
, startup          : startup
, stopVisualizing  : stopVisualizing
, toggleHelp       : toggleHelp
}
