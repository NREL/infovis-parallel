
'use strict';


const Rendering = {
  Frames     : require("./rendering/frames"    )
, Linear     : require("./rendering/linear"    )
, Program    : require("./rendering/program"   )
, Projection : require("./rendering/projection")
, Selector   : require("./rendering/selector"  )
, Shapes     : require("./rendering/shapes"    )
, Text       : require("./rendering/text"      )
}


require("./gl-matrix")


const DEBUG = true


const zero = glMatrix.vec3.fromValues(0, 0, 0)


function setupCanvas(gl, useBlending = true, useCulling = true) {

  if (DEBUG) console.debug("setupCanvas")

  gl.viewport(0, 0, gl.canvas.width, gl.canvas.height)

  gl.clearColor(0., 0., 0., 1.)
  gl.clearDepth(1.0)

  gl.enable(gl.DEPTH_TEST)
  gl.depthFunc(gl.LEQUAL)

  if (useBlending) {
    gl.enable(gl.BLEND)
    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
  }

  if (useCulling) {
    gl.enable(gl.CULL_FACE)
    gl.cullFace(gl.BACK)
  }

  gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
}


function initializeGraphics(gl, initialViewer, initialTool) {
  const manager = Rendering.Frames.createManager(gl)
  return {
    manager  : manager
  , selector : Rendering.Selector.create(gl, manager.program)
  , pov      : initialViewer
  , tool     : initialTool
  , text     : ""
  , offset   : {position: zero, rotation: Rendering.Linear.fromEulerd(zero)}
  }
}


function visualizeBuffers(gl, configuration, requests) {

  const graphics = initializeGraphics(
    gl
  , {
      position: configuration.initial.view.position
    , rotation: Rendering.Linear.fromEulerd(configuration.initial.view.orientation)
    }
  , {
      position: configuration.initial.tool.position
    , rotation: Rendering.Linear.fromEulerd(configuration.initial.tool.orientation)
    }
  )

  if (DEBUG)
    window.theGraphics = graphics

  function animation(timestamp) {


    if (requests.length > 0) {

      while (requests.length > 0) {

        const request = requests.pop()

        if (DEBUG) {
          console.debug("animation: request =", request)
          window.theRequest = request
        }

        Rendering.Frames.insert(gl, request.getUpsertList(), graphics.manager)

      }

      setupCanvas(gl)

      Rendering.Frames.prepare(gl, graphics.manager)
      Rendering.Selector.prepare(gl, graphics.selector, graphics.tool.position, graphics.tool.rotation)

      graphics.manager.projection = Rendering.Projection.projection(configuration.display, graphics.pov.position)
      graphics.manager.modelView = Rendering.Projection.modelView(graphics.offset.position, graphics.offset.rotation)

      Rendering.Frames.draw(gl, graphics.manager )
      Rendering.Selector.draw(gl, graphics.selector, graphics.manager.projection, graphics.manager.modelView)

    }

    window.requestAnimationFrame(animation)

  }

  window.requestAnimationFrame(animation)
}


module.exports = {
  setupCanvas        : setupCanvas
, initializeGraphics : initializeGraphics
, visualizeBuffers   : visualizeBuffers
}
