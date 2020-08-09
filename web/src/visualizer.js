
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


new WebXRPolyfill()


const zero = vec3.fromValues(0, 0, 0)


export function setupCanvas(gl, useBlending = !DEBUG, useCulling = !DEBUG) {

  if (DEBUG) console.debug("setupCanvas")

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
    graphics.message.image = Text.makePixmap(graphics.message.text, "white", 150)
    if (DEBUG) console.debug("processRequest: message = '", graphics.message.text, "'")
  }

  return dirty

}


export function setupXR(action) {
  if (navigator.xr)
    navigator.xr.isSessionSupported('immersive-vr').then((supported) => {
      if (DEBUG) console.debug("setupXR: supported = ", supported)
      action(supported)
    })
  else
    action(false)
}


let isRunning = false

var xrReferenceSpace = null


function drawAll(gl, graphics, perspective = mat4.create()) {

  if (!(new RegExp("^ *$")).test(graphics.message.text))
    Text.drawText(
      gl
    , graphics.message.image
    , [vec3.fromValues(0, 0, -1), vec3.fromValues(1, 0, -1), vec3.fromValues(0, 1, -1)]
    , 0.075
    , perspective
    , mat4.create()
    , true
    )

  Selector.draw(gl, graphics.selector, graphics.manager.projection, graphics.manager.modelView)
  Frames.draw(gl, graphics.manager)

}


export function visualizeBuffers(gl, configuration, requestQueue, keyQueue, respond, stopper) {

  let starting = Date.now() + 2000

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

  Navigation.resetGamepad()

  setupCanvas(gl)

  function animation(timestamp, xrFrame = null) {

    if (!isRunning) {
      keyQueue.length = 0
      requestQueue.length = 0
      return
    }

    const now = new Date()
    const dirtyRequest  = (starting && starting < now) || requestQueue.length > 0
    let   dirtyResponse = (starting && starting < now) || keyQueue.length > 0

    const gamepad = Navigation.interpretGamepad(graphics)
    dirtyResponse |= gamepad.dirty
  
    while (keyQueue.length > 0)
      Navigation.interpretKeyboard(keyQueue.pop(), graphics)
  
    while (requestQueue.length > 0)
      dirtyResponse |= processRequest(gl, graphics, requestQueue.pop())

    if (xrFrame || dirtyRequest || dirtyResponse) {

      starting = null

      Frames.prepare(gl, graphics.manager)
      if (dirtyResponse)
        Selector.prepare(gl, graphics.selector, graphics.tool.position, graphics.tool.rotation)

      if (xrFrame) {

        const xrSession = xrFrame.session

        const pose = xrFrame.getViewerPose(xrReferenceSpace)

        graphics.pov.position = vec3.fromValues(
          pose.transform.position.x
        , pose.transform.position.y
        , pose.transform.position.z
        )
        graphics.pov.rotation = quat.fromValues(
          pose.transform.orientation.x
        , pose.transform.orientation.y
        , pose.transform.orientation.z
        , pose.transform.orientation.w
        )

        const delta = vec3.fromValues(0.5, 0.5, 2.5)
        graphics.manager.modelView = Projection.modelView(
          vec3.scaleAndAdd(vec3.create(), graphics.offset.position, delta, -1)
        , graphics.offset.rotation
        )

        let layer = xrSession.renderState.baseLayer
        gl.bindFramebuffer(gl.FRAMEBUFFER, layer.framebuffer)
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

        for (let view of pose.views) {

          const viewport = layer.getViewport(view);
          gl.viewport(viewport.x, viewport.y, viewport.width, viewport.height)

          graphics.manager.projection = mat4.multiply(
            mat4.create()
          , view.projectionMatrix
          , view.transform.inverse.matrix
          )

          drawAll(gl, graphics, view.projectionMatrix)

        }

      } else {

        gl.viewport(0, 0, gl.canvas.width, gl.canvas.height)
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        graphics.manager.modelView = Projection.modelView(graphics.offset.position, graphics.offset.rotation)

        const eyes = configuration.display.mode == "stereo" ? 2 : 1
        for (let eye = 0; eye < eyes; ++eye) {

          let viewport = {
            x      : (eyes - 1) * eye * gl.canvas.width / 2
          , y      : 0
          , width  : gl.canvas.width / eyes
          , height : gl.canvas.height
          }
          gl.viewport(viewport.x, viewport.y, viewport.width, viewport.height)

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

          drawAll(gl, graphics)

        }

      }

    }

    if (dirtyResponse) {
      const response = new proto.Infovis.Response()
      response.setShown(graphics.manager.current          )
      response.setViewloc   (makeLocation(graphics.pov   ))
      response.setToolloc   (makeLocation(graphics.tool  ))
      response.setOffsetloc (makeLocation(graphics.offset))
      response.setDepressed (gamepad.depressed            )
      response.setAnalogList(gamepad.analog               )
      respond(response)
    }

    if (xrFrame)
      xrFrame.session.requestAnimationFrame(animation)
    else
      window.requestAnimationFrame(animation)

  }

  if (configuration.display.mode == "webxr") {

    navigator.xr.requestSession('immersive-vr').then((xrSession) => {
      if (DEBUG) console.debug("visualizeBuffers: xrSession = ", xrSession)
      xrSession.addEventListener("end", stopper)
      let xrLayer = new XRWebGLLayer(xrSession, gl)
      xrSession.updateRenderState({baseLayer: xrLayer})
      xrSession.requestReferenceSpace("local").then((referenceSpace) => {
        xrReferenceSpace = referenceSpace
        xrSession.requestAnimationFrame(animation)
      })
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
