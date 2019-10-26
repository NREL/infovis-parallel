
const Rendering = {
  Buffers    : require("./rendering/buffers"   )
, Frames     : require("./rendering/frames"    )
, Linear     : require("./rendering/linear"    )
, Program    : require("./rendering/program"   )
, Projection : require("./rendering/projection")
, Selector   : require("./rendering/selector"  )
, Shapes     : require("./rendering/shapes"    )
}

require("./gl-matrix")


const mat4 = glMatrix.mat4
const vec3 = glMatrix.vec3

const zero = vec3.fromValues(0, 0, 0)


// FIXME: Investigate
const useBlending = true
const useCulling = true


function setupCanvas(gl) {

  console.debug("setupCanvas")

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
    , rotation: configuration.initial.view.orientation
    }
  , {
      position: configuration.initial.tool.position
    , rotation: configuration.initial.tool.orientation
    }
  )


  function animation(timestamp) {


    if (requests.length > 0) {

      while (requests.length > 0) {
        const request = requests.pop()
        console.debug("animation: request =", request)
        Rendering.Frames.insert(gl, request.getUpsertList(), graphics.manager)
      }

      setupCanvas(gl)

      Rendering.Program.selectShapeProgram(gl, graphics.manager.program)

      Rendering.Frames.prepare(gl, graphics.manager)
      Rendering.Selector.prepare(gl, graphics.tool.position, graphics.tool.rotation, graphics.selector)

      const projection = Rendering.Projection.projection(configuration.display, graphics.pov.position)
      const modelView = Rendering.Projection.modelView(graphics.offset.position, graphics.offset.rotation)

      const projection1 = mat4.perspective(
        mat4.create()
      , 45 * Math.PI / 180
      , gl.canvas.clientWidth / gl.canvas.clientHeight
      , configuration.display.nearPlane
      , configuration.display.farPlane
      )

      Rendering.Frames.draw(gl, graphics.manager, projection, modelView)
      Rendering.Selector.draw(gl, graphics.selector, projection, modelView)

      console.log("projection =", projection)
      console.log("projection1 =", projection1)

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
