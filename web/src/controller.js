
import * as Configuration from "./configuration"
import * as Connection    from "./connection"
import * as Visualizer    from "./visualizer"


const version = "Version 0.4.5"


export function download() {
  Configuration.download()
}


export function load() {
  Configuration.load()
  Configuration.updatePanel()
}


export function save() {
  Configuration.save()
}


export function reset() {
  Configuration.reset()
  Configuration.updatePanel()
}


export function updatePanel() {
  Configuration.updatePanel()
}


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

  version_num.innerText = version

  uiAddress.addEventListener("keyup", function(event) {
    if (event.keyCode === 13) {
      event.preventDefault();
      uiConnect.click();
    }
  })

  document.addEventListener("keydown", keyHandler)

  theContext = uiCanvas.getContext("webgl2", {xrCompatible: true})
  const gl = theContext

  gl.canvas.width  = window.innerWidth
  gl.canvas.height = window.innerHeight

  Visualizer.setupCanvas(gl)

  Configuration.compute()
  Connection.updateButtons()

  Visualizer.setupXR(function(hasXR) {
    if (hasXR)
      uiXR.checked = true
    else
      uiXR.disabled = true
    Configuration.updatePanel()
  })

}


export function stopVisualizing() {
  Connection.unconnect()
  Visualizer.stop()
  isVisualizing = false
}


export function startVisualizing() {
  const configuration = Configuration.update()
  Connection.reconnect(configuration, echoHandler, disconnectHandler)
  isVisualizing = true
  if (uiStereo.checked)
    uiCanvas.requestFullscreen()
  Visualizer.visualizeBuffers(
    theContext
  , configuration
  , requestQueue
  , keyQueue
  , Connection.send
  , stopVisualizing
  )
}


export function toggleHelp() {
  uiKeyboard.style.visibility = uiKeyboard.style.visibility == "visible" ? "hidden" : "visible"
}
