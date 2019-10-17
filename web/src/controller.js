// Use protocol buffers.
require("./infovis.proto3_pb")


// Set up the document.
function startup() {

  var gl = glCanvas.getContext("webgl")

  gl.canvas.width  = window.innerWidth
  gl.canvas.height = window.innerHeight

  gl.clearColor(0.0, 0.0, 0.0, 1.0);
  gl.clear(gl.COLOR_BUFFER_BIT);

}


var msg = proto.Infovis.Geometry()


// Export functions.
module.exports = {
  startup: startup
}
