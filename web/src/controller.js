
import * as Configuration from "./configuration"
import * as Connection    from "./connection"
import * as Visualizer    from "./visualizer"


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


export function startup() {

  document.addEventListener("keydown", keyHandler)

  theContext = uiCanvas.getContext("webgl2")
  const gl = theContext

  gl.canvas.width  = window.innerWidth
  gl.canvas.height = window.innerHeight

  Visualizer.setupCanvas(gl)

  Configuration.compute()
  Connection.updateButtons()

}


export function startVisualizing() {
  const configuration = Configuration.update()
  Connection.reconnect(configuration, echoHandler, disconnectHandler)
  isVisualizing = true
  Visualizer.visualizeBuffers(theContext, configuration, requestQueue, keyQueue, Connection.send)
}


export function stopVisualizing() {
  Connection.unconnect()
  Visualizer.stop()
  isVisualizing = false
}


export function toggleHelp() {
  uiKeyboard.style.visibility = uiKeyboard.style.visibility == "visible" ? "hidden" : "visible"
}
