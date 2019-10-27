
'use strict';


const Transport = require("./transport")


let theConnection = null


function updateButtons() {
  uiConnector.style.visibility = theConnection == null ? "visible" : "hidden"
  uiVisualize.style.visibility = theConnection != null ? "visible" : "hidden"
}


function disconnected() {
  console.debug("disconnected")
  theConnection = null
  updateButtons()
}


function reconnect(configuration, handler) {
  const url = configuration.server.address
  console.debug("reconnect: url =", url)
  theConnection = Transport.connect(url, handler, disconnected)
  updateButtons()
}


function unconnect() {
  console.debug("unconnect")
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
