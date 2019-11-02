
'use strict';


const Transport = require("./transport")


const DEBUG = false


let theConnection = null


function updateButtons() {
  uiConnector.style.visibility = theConnection == null ? "visible" : "hidden"
  uiVisualize.style.visibility = theConnection != null ? "visible" : "hidden"
}


function disconnected(handler) {
  if (DEBUG) console.debug("disconnected")
  theConnection = null
  updateButtons()
  handler()
}


function reconnect(configuration, handler, disconnector) {
  const url = configuration.server.address
  if (DEBUG) console.debug("reconnect: url =", url)
  theConnection = Transport.connect(url, handler, () => disconnected(disconnector))
  updateButtons()
}


function unconnect() {
  if (DEBUG) console.debug("unconnect")
  if (theConnection != null)
    Transport.disconnect(theConnection)
  theConnection = null
  updateButtons()
}


module.exports = {
  current       : () => theConnection
, reconnect     : reconnect
, unconnect     : unconnect
, updateButtons : updateButtons
}
