
import * as Frames     from "./rendering/frames"
import * as Navigation from "./navigation"
import * as Linear     from "./rendering/linear"
import * as Projection from "./rendering/projection"
import * as Selector   from "./rendering/selector"
import * as Text       from "./rendering/text"


const DEBUG = false


const quat = glMatrix.quat
const mat4 = glMatrix.mat4
const vec3 = glMatrix.vec3


new WebVRPolyfill()


const usePOV = false


const zero = vec3.fromValues(0, 0, 0)


export function setupCanvas(gl, useBlending = !DEBUG, useCulling = !DEBUG) {

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
    theManager = Frames.createManager(gl)
  if (theSelector == null)
    theSelector = Selector.create(gl, theManager.program)
  Frames.destroyManager(gl, theManager)
}


function initializeGraphics(gl, initialViewer, initialTool) {
  ensureManager(gl)
  return {
    manager  : theManager
  , selector : theSelector
  , pov      : initialViewer
  , tool     : initialTool
  , offset   : {position: zero, rotation: Linear.fromEulerd(zero)}
  , message  : {text: "", image: Text.makePixmap("")}
  }
}


function makeLocation(positionRotation) {
  const result = new proto.Infovis.Location()
  result.setPosx(positionRotation.position[0])
  result.setPosy(positionRotation.position[1])
  result.setPosz(positionRotation.position[2])
  result.setRotx(positionRotation.rotation[0])
  result.setRoty(positionRotation.rotation[1])
  result.setRotz(positionRotation.rotation[2])
  result.setRotw(positionRotation.rotation[3])
  return result
}


function processRequest(gl, graphics, request) {

  let dirty = false

  if (DEBUG) console.debug("processRequest: request =", request)

  if (request.getShow() != 0) {
    if (DEBUG) console.debug("processRequest: show =", request.getShow())
    graphics.manager.current = request.getShow()
    dirty = true
  }

  if (request.getReset()) {
    if (DEBUG) console.debug("processRequest: reset")
    Frames.reset(graphics.manager)
  }

  if (request.getUpsertList().length > 0) {
    if (DEBUG) console.debug("processRequest: upsert", request.getUpsertList().length)
    Frames.insert(gl, request.getUpsertList(), graphics.manager)
  }

  if (request.getDeleteList().length > 0) {
    if (DEBUG) console.debug("anamiate: delete", request.getDeleteList().length)
    Frames.deletE(request.getDeleteList(), graphics.manager)
  }

  if (request.hasViewloc()) {
    const loc = request.getViewloc()
    graphics.pov.position = vec3.fromValues(loc.getPosx(), loc.getPosy(), loc.getPosz())
    graphics.pov.rotation = quat.fromValues(loc.getRotx(), loc.getRoty(), loc.getRotz(), loc.getRotw())
    dirty = true
    if (DEBUG) console.debug("processRequest: view =", graphics.pov)
  }

  if (request.hasToolloc()) {
    const loc = request.getToolloc()
    graphics.tool.position = vec3.fromValues(loc.getPosx(), loc.getPosy(), loc.getPosz())
    graphics.tool.rotation = quat.fromValues(loc.getRotx(), loc.getRoty(), loc.getRotz(), loc.getRotw())
    dirty = true
    if (DEBUG) console.debug("processRequest: tool =", graphics.tool)
  }

  if (request.hasOffsetloc()) {
    const loc = request.getOffsetloc()
    graphics.offset.position = vec3.fromValues(loc.getPosx(), loc.getPosy(), loc.getPosz())
    graphics.offset.rotation = quat.fromValues(loc.getRotx(), loc.getRoty(), loc.getRotz(), loc.getRotw())
    if (DEBUG) console.debug("processRequest: offset =", graphics.offset)
  }

  if (request.getMessage() != "") {
    graphics.message.text = request.getMessage()
    graphics.message.image = Text.makePixmap(graphics.message.text, "white")
    if (DEBUG) console.debug("processRequest: message = '", graphics.message.text, "'")
  }

  return dirty

}


let vrDisplay = null


export function setupVR(action) {
  navigator.getVRDisplays().then(function(displays) {
    const hasVR = displays.length > 0
    vrDisplay = hasVR ? displays[displays.length - 1] : null
    action(hasVR)
  })
}


let isRunning = false


export function visualizeBuffers(gl, configuration, requestQueue, keyQueue, respond) {

  const useVR = configuration.display.mode == "webvr"

  if (vrDisplay != null) {
    vrDisplay.depthNear = configuration.display.nearPlane
    vrDisplay.depthFar  = configuration.display.farPlane
  }

  isRunning = true

  const graphics = initializeGraphics(
    gl
  , {
      position: configuration.initial.view.position
    , rotation: Linear.fromEulerd(configuration.initial.view.orientation)
    }
  , {
      position: configuration.initial.tool.position
    , rotation: Linear.fromEulerd(configuration.initial.tool.orientation)
    }
  )

  Text.ensureShaders(gl)

  function animation(timestamp) {

    if (!isRunning) {
      keyQueue.length = 0
      requestQueue.length = 0
      return
    }

    const dirtyRequest  = requestQueue.length > 0
    let   dirtyResponse = keyQueue.length > 0

    dirtyResponse |= Navigation.interpretGamepad(graphics)

    while (keyQueue.length > 0)
      Navigation.interpretKeyboard(keyQueue.pop(), graphics)

    while (requestQueue.length > 0)
      dirtyResponse |= processRequest(gl, graphics, requestQueue.pop())

    if (useVR || dirtyRequest || dirtyResponse) {

      setupCanvas(gl)

      Frames.prepare(gl, graphics.manager)
      Selector.prepare(gl, graphics.selector, graphics.tool.position, graphics.tool.rotation)

      const eyes = useVR || configuration.display.mode == "stereo" ? 2 : 1
      for (let eye = 0; eye < eyes; ++eye) {

        gl.viewport((eyes - 1) * eye * gl.canvas.width / 2, 0, gl.canvas.width / eyes, gl.canvas.height)

        if (useVR) {

          const frameData = new VRFrameData()
          vrDisplay.getFrameData(frameData)

          const pose = frameData.pose
          graphics.pov.position = pose.position    != null ? pose.position    : vec3.create()
          graphics.pov.rotation = pose.orientation != null ? pose.orientation : quat.create()

          graphics.manager.projection = eye == 0 ? frameData.leftProjectionMatrix : frameData.rightProjectionMatrix
          const view = mat4.multiply(
            mat4.create()
          , eye == 0 ? frameData.leftViewMatrix : frameData.rightViewMatrix
          , usePOV ? Projection.modelView(graphics.pov.position, graphics.pov.rotation) : mat4.create()
          )
          const model = Projection.modelView(graphics.offset.position, graphics.offset.rotation)
          graphics.manager.modelView = mat4.multiply(mat4.create(), model, view)

        } else {

          const eyeOffset = vec3.scale(
            vec3.create()
          , vec3.fromValues(
              configuration.display.eyeSeparation[0]
            , configuration.display.eyeSeparation[1]
            , configuration.display.eyeSeparation[2]
            )
          , (eyes - 1) * (2 * eye - 1) / 2
          )
          const eyePosition = vec3.add(
            vec3.create()
          , graphics.pov.position
          , vec3.transformQuat(vec3.create(), eyeOffset, graphics.pov.rotation)
          )

          graphics.manager.projection = Projection.projection(configuration.display, eyePosition)
          graphics.manager.modelView = Projection.modelView(graphics.offset.position, graphics.offset.rotation)

        }

        Text.drawText(
          gl
        , graphics.message.image
        , [
            vec3.fromValues(-0.9, -0.9, 0)
          , vec3.fromValues( 1.0, -0.9, 0)
          , vec3.fromValues(-0.9,  0.0, 0)
          ]
        , 0.075
        , mat4.create()
        , mat4.create()
        )

        Selector.draw(gl, graphics.selector, graphics.manager.projection, graphics.manager.modelView)
        Frames.draw(gl, graphics.manager )

      }

    }

    if (dirtyResponse) {
      const response = new proto.Infovis.Response()
      response.setShown(graphics.manager.current)
      response.setViewloc   (makeLocation(graphics.pov   ))
      response.setToolloc   (makeLocation(graphics.tool  ))
      response.setOffsetloc (makeLocation(graphics.offset))
      respond(response)
    }

    if (useVR) {
      vrDisplay.submitFrame()
      vrDisplay.requestAnimationFrame(animation)
    } else
      window.requestAnimationFrame(animation)

  }

  if (useVR && vrDisplay != null) {

    const eye = vrDisplay.getEyeParameters("left")
    uiCanvas.width  = eye.renderWidth
    uiCanvas.height = eye.renderHeight

    vrDisplay.requestPresent([{source: uiCanvas}]).then(function() {
      animation()
    })

  } else {

    uiCanvas.width  = window.innerWidth
    uiCanvas.height = window.innerHeight

    window.requestAnimationFrame(animation)

  }

}


export function stop() {
  isRunning = false
}
