
'use strict';

const Keyboard = require("./keyboard")
const Rendering = {
  Frames     : require("./rendering/frames"    )
, Linear     : require("./rendering/linear"    )
, Program    : require("./rendering/program"   )
, Projection : require("./rendering/projection")
, Selector   : require("./rendering/selector"  )
, Text       : require("./rendering/text"      )
}


require("./gl-matrix")


const DEBUG = false


const forgetKeys = true


const quat = glMatrix.quat
const vec3 = glMatrix.vec3


const zero = vec3.fromValues(0, 0, 0)


function setupCanvas(gl, useBlending = !DEBUG, useCulling = !DEBUG) {

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


let theManager  = null
let theSelector = null


function ensureManager(gl) {
  if (theManager == null)
    theManager = Rendering.Frames.createManager(gl)
  if (theSelector == null)
    theSelector = Rendering.Selector.create(gl, theManager.program)
  Rendering.Frames.destroyManager(gl, theManager)
}


function initializeGraphics(gl, initialViewer, initialTool) {
  ensureManager(gl)
  return {
    manager  : theManager
  , selector : theSelector
  , pov      : initialViewer
  , tool     : initialTool
  , offset   : {position: zero, rotation: Rendering.Linear.fromEulerd(zero)}
  , message  : ""
  }
}


let isRunning = false


function visualizeBuffers(gl, configuration, requestQueue, keyQueue) {

  isRunning = true

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

  Rendering.Text.ensureShaders(gl)

  function animation(timestamp) {

    if (!isRunning) {
      keyQueue.length = 0
      requestQueue.length = 0
      return
    }

    const dirty = keyQueue.length > 0 || requestQueue.length > 0

    while (keyQueue.length > 0)
      Keyboard.interpret(keyQueue.pop(), graphics)
    if (forgetKeys)
      keyQueue.length = 0

    while (requestQueue.length > 0) {

      const request = requestQueue.pop()

      if (DEBUG) console.debug("animation: request =", request)

      if (request.getShow() != 0) {
        if (DEBUG) console.log("animate: show =", request.getShow())
        graphics.manager.current = request.getShow()
     }

      if (request.getReset()) {
        if (DEBUG) console.log("animate: reset")
        Rendering.Frames.reset(graphics.manager)
      }

      if (request.getUpsertList().length > 0) {
        if (DEBUG) console.log("animate: upsert", request.getUpsertList().length)
        Rendering.Frames.insert(gl, request.getUpsertList(), graphics.manager)
      }

      if (request.getDeleteList().length > 0) {
        if (DEBUG) console.log("anamiate: delete", request.getDeleteList().length)
        Rendering.Frames.delete(request.getDeleteList(), graphics.manager)
      }

      if (request.hasViewloc()) {
        const loc = request.getViewloc()
        graphics.pov.position = vec3.fromValues(loc.getPosx(), loc.getPosy(), loc.getPosz())
        graphics.pov.rotation = quat.fromValues(loc.getRotx(), loc.getRoty(), loc.getRotz(), loc.getRotw())
        if (DEBUG) console.log("animate: view =", graphics.pov)
      }

      if (request.hasToolloc()) {
        const loc = request.getToolloc()
        graphics.tool.position = vec3.fromValues(loc.getPosx(), loc.getPosy(), loc.getPosz())
        graphics.tool.rotation = quat.fromValues(loc.getRotx(), loc.getRoty(), loc.getRotz(), loc.getRotw())
        if (DEBUG) console.log("animate: tool =", graphics.tool)
      }

      if (request.hasOffsetloc()) {
        const loc = request.getOffsetloc()
        graphics.offset.position = vec3.fromValues(loc.getPosx(), loc.getPosy(), loc.getPosz())
        graphics.offset.rotation = quat.fromValues(loc.getRotx(), loc.getRoty(), loc.getRotz(), loc.getRotw())
        if (DEBUG) console.log("animate: offset =", graphics.offset)
      }

      if (request.getMessage() != "") {
        graphics.message = request.getMessage()
        if (DEBUG) console.log("animate: message = '", graphics.message, "'")
      }

    }

    if (dirty) {

      setupCanvas(gl)

      Rendering.Frames.prepare(gl, graphics.manager)
      Rendering.Selector.prepare(gl, graphics.selector, graphics.tool.position, graphics.tool.rotation)

      graphics.manager.projection = Rendering.Projection.projection(configuration.display, graphics.pov.position)
      graphics.manager.modelView = Rendering.Projection.modelView(graphics.offset.position, graphics.offset.rotation)

      Rendering.Frames.draw(gl, graphics.manager )
      Rendering.Selector.draw(gl, graphics.selector, graphics.manager.projection, graphics.manager.modelView)

      const message = uiMessage.innerText
      if (graphics.message != message)
        uiMessage.innerText = graphics.message

    }

    window.requestAnimationFrame(animation)

  }

  window.requestAnimationFrame(animation)
}


module.exports = {
  setupCanvas      : setupCanvas
, visualizeBuffers : visualizeBuffers
, stop             : function() {isRunning = false}
}
