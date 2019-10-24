
const Rendering = {
  Frames   : require("../rendering/frames"  )
, Linear   : require("../rendering/linear"  )
, Selector : require("../rendering/selector")
}

require("../gl-matrix")

const vec3 = glMatrix.vec3

const zero = vec3.fromValues(0, 0, 0)


function initialize(gl, initialViewer, initialTool) {
  const manager = Rendering.Frames.createManager(gl)
  return {
    startRef    : null
  , lockRef     : null
  , managerRef  : manager
  , selectorRef : Rendering.Selector.createSelector(gl, manager.program)
  , povRef      : [initialViewer[0], Rendering.Linear.fromEulerd(initialViewer[1])]
  , toolRef     : [initialTool  [0], Rendering.Linear.fromEulerd(initialTool  [1])]
  , textRef     : ""
  , offsetRef   : [zero            , Rendering.Linear.fromEulerd(zero            )]
  }
}


function visualize(gl, viewer, initialViewer, initialTool, debug, logChannel, requestChannel, responseChannel) {

  const graphics = initialize(initialViewer, initialTool)

}


module.exports = {
  initialize : initialize
, visualize : visualize
}
