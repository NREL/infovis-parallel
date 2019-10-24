
const Rendering = {
  Frames   : require("./rendering/frames"  )
, Linear   : require("./rendering/linear"  )
, Selector : require("./rendering/selector")
}

require("./gl-matrix")


const vec3 = glMatrix.vec3

const zero = vec3.fromValues(0, 0, 0)


function setupCanvas(gl) {

  gl.enable(gl.DEPTH_TEST)
  gl.depthFunc(gl.LESS)

  gl.enable(gl.BLEND)
  gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

  // FIXME: Experiment to see if this works well with alpha.
  gl.enable(gl.CULL_FACE)

  gl.viewport(0, 0, gl.canvas.width, gl.canvas.height)

  gl.clearColor(0.0, 0.0, 0.0, 1.0)
  gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

}


function initializeGraphics(gl, initialViewer, initialTool) {
  const manager = Rendering.Frames.createManager(gl)
  return {
    start    : null
  , lock     : null
  , manager  : manager
  , selector : Rendering.Selector.createSelector(gl, manager.program)
  , pov      : [initialViewer[0], Rendering.Linear.fromEulerd(initialViewer[1])]
  , tool     : [initialTool  [0], Rendering.Linear.fromEulerd(initialTool  [1])]
  , text     : ""
  , offset   : [zero            , Rendering.Linear.fromEulerd(zero            )]
  }
}


function visualizeBuffers(gl, configuration, requests) {

  const graphics = initializeGraphics(
    gl
  , [configuration.initial.view.position, configuration.initial.view.orientation]
  , [configuration.initial.tool.position, configuration.initial.tool.orientation]
  )

  function animation(timestamp) {
    while (requests.length > 0) {
      const request = requests.pop()
      console.log("Popped request: ", request)
      Rendering.Frames.insert(gl, request.getUpsertList(), graphics.manager)
    }
    Rendering.Frames.draw(gl, graphics.manager)
    window.requestAnimationFrame(animation)
  }

  window.requestAnimationFrame(animation)
}


module.exports = {
  setupCanvas        : setupCanvas
, initializeGraphics : initializeGraphics
, visualizeBuffers   : visualizeBuffers
}
