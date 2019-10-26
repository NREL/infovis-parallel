
const Rendering = {
  Debug      : require("./rendering/debug"     )
,Frames     : require("./rendering/frames"    )
, Linear     : require("./rendering/linear"    )
, Program    : require("./rendering/program"   )
, Projection : require("./rendering/projection")
, Selector   : require("./rendering/selector"  )
}

require("./gl-matrix")


const mat4 = glMatrix.mat4
const vec3 = glMatrix.vec3

const zero = vec3.fromValues(0, 0, 0)


function setupCanvas(gl) {

  console.debug("setupCanvas")

  gl.viewport(0, 0, gl.canvas.width, gl.canvas.height)

  gl.clearColor(0., 0., 0., 1.)
  gl.clearDepth(1.0)

  gl.enable(gl.DEPTH_TEST)
  gl.depthFunc(gl.LEQUAL)

  // FIXME: Test before using.
  if (false) {
    gl.enable(gl.BLEND)
    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
  }

  // FIXME: Test before using.
  if (false) {
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

  if (true) {
    Rendering.Debug.main(gl)
    return
  }

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

      // FIXME: Test before using.
      if (false) {

        const  projection = Rendering.Projection.projection(configuration.display, graphics.pov.position)
        const modelView = Rendering.Projection.modelView(graphics.offset.position, graphics.offset.rotation)
        Rendering.Program.setProjectionModelView(gl, graphics.manager.program, projection, modelView)

      } else {

        console.debug("animation: <alternative pmv>")
        const fieldOfView = 45 * Math.PI / 180;   // in radians
        const aspect = gl.canvas.clientWidth / gl.canvas.clientHeight;
        const zNear = 0.1;
        const zFar = 100.0;
        const projection = mat4.create();
        mat4.perspective(projection, fieldOfView, aspect, zNear, zFar);
        const modelView = mat4.create();
        mat4.translate(modelView, modelView, [-0.0, 0.0, -15.0]);
        Rendering.Program.setProjectionModelView(gl, graphics.manager.program, projection, modelView)

      }

      Rendering.Frames.draw(gl, graphics.manager)
      Rendering.Selector.draw(gl, graphics.selector)

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
