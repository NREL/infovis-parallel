
'use strict';


const Configuration = require("./configuration")
const Connection    = require("./connection"   )
const Visualizer    = require("./visualizer"   )


const DEBUG = false


const requestQueue = []

const keyQueue = []

let isVisualizing = false

let theContext = null


function echoHandler(connection, request) {
  if (DEBUG) console.debug("echoHandler: request =", request)
  requestQueue.unshift(request)
}


function disconnectHandler(lostConnection) {
  if (lostConnection)
    window.alert("The WebSocket disconnected.")
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

  isVisualizing = true

  const configuration = Configuration.update()
  Connection.reconnect(configuration, echoHandler, disconnectHandler)
  Visualizer.visualizeBuffers(theContext, configuration, requestQueue, keyQueue)

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
