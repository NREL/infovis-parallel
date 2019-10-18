const Transport     = require("./transport"    )


var theConnection = null


function updateButtons() {
  uiConnector.style.visibility = theConnection == null ? "visible" : "hidden"
  uiVisualize.style.visibility = theConnection != null ? "visible" : "hidden"
}

function disconnected() {
  console.log("Disconnected")
  theConnection = null
  updateButtons()
}

function reconnect(configuration, handler) {
  var url = configuration.server.address
  console.log("Connect:", url)
  theConnection = Transport.connect(url, handler, disconnected)
  updateButtons()
}

function unconnect() {
  console.log("Disconnect")
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
