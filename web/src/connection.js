
import * as Transport from "./transport"


const DEBUG = false


let theConnection = null


export function updateButtons() {
  uiConnector.style.visibility = theConnection == null ? "visible" : "hidden"
  uiVisualize.style.visibility = theConnection != null ? "visible" : "hidden"
}


function disconnected(handler) {
  theConnection = null
  updateButtons()
  handler()
}


export function reconnect(configuration, handler, disconnector) {
  const url = configuration.server.address
  if (DEBUG) console.debug("reconnect: url =", url)
  theConnection = Transport.connect(
    url
  , handler
  , function(event) {
      if (DEBUG) console.debug("disconnected: event =", event)
      disconnected(disconnector)
    }
  )
  updateButtons()
  return theConnection != null
}


export function send(buffer) {
  Transport.send(theConnection, buffer)
}


export function unconnect() {
  if (DEBUG) console.debug("unconnect")
  if (theConnection != null) {
    const oldConnection = theConnection
    theConnection = null
    Transport.disconnect(oldConnection)
  }
  updateButtons()
}


export function current() {
  return theConnection
}
