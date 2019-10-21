
const Graphics = require("./visualizer/graphics")


function setup(gl) {

  gl.enable(gl.DEPTH_TEST);
  gl.depthFunc(gl.LESS)

  gl.enable(gl.BLEND);
  gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

  // FIXME: Experiment to see if this works well with alpha.
  gl.enable(gl.CULL_FACE);

  // FIXME: In WebGL, this needs to be implemented in a fragment shader.
//gl.alphaFunc(gl.GREATER, 0)

  gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);

  gl.clearColor(0.0, 0.0, 0.0, 1.0);
  gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

}


function visualizeBuffers(gl, configuration) {
  const graphics = Graphics.initialize(
    gl
  , [configuration.initial.view.position, configuration.initial.view.orientation]
  , [configuration.initial.tool.position, configuration.initial.tool.orientation]
  )
}


module.exports = {
  setup            : setup
, visualizeBuffers : visualizeBuffers
}
