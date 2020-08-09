
import * as Frames     from "../rendering/frames"
import * as Navigation from "../navigation"


const quat = glMatrix.quat
const vec3 = glMatrix.vec3


const DEBUG = false


const center = vec3.fromValues(0.5, 0.5, 0.5)


let lastButton = null

let offsetRotation = null


export function reset() {
  lastButton = Date.now()
}


export function interpret(graphics, xrFrame, xrReferenceSpace, delta) {

  const inputSources = xrFrame.session.inputSources
  if (!inputSources || !inputSources.length || !inputSources[0].gripSpace)
    return false
  const inputSource = inputSources[0]
  const inputPose = xrFrame.getPose(inputSource.gripSpace, xrReferenceSpace);

  const x = Navigation.x

  const frames = Frames.listFrames(graphics.manager)
  const minFrame = Math.min(...frames)
  const maxFrame = Math.max(...frames)

  const position = vec3.fromValues(
    inputPose.transform.position.x
  , inputPose.transform.position.y
  , inputPose.transform.position.z
  )
  const rotation = quat.fromValues(
    inputPose.transform.orientation.x
  , inputPose.transform.orientation.y
  , inputPose.transform.orientation.z
  , inputPose.transform.orientation.w
  )

  const now = Date.now()
  const vetoPeriod = 300
  const vetoButtons = now - lastButton <= vetoPeriod

  const buttons = inputSource.gamepad.buttons
  const axes    = inputSource.gamepad.axes

  if (!vetoButtons && axes.length >= 4 && axes[3] != 0) {
    const deltaPosition = vec3.scale(
      vec3.create()
    , vec3.transformQuat(
        vec3.create()
      , vec3.fromValues(0, 0, 1)
      , rotation
      )
    , x.deltaOffsetPosition * axes[3]
    )
    graphics.offset.position = vec3.add(vec3.create(), graphics.offset.position, deltaPosition)
  }

  if (!vetoButtons && buttons.length >= 2 && buttons[1].pressed && axes.length >= 4) {
    lastButton = now
    if (offsetRotation)
      offsetRotation = null
    else
      offsetRotation = quat.multiply(
        quat.create()
      , quat.invert(
          quat.create()
        , rotation
        )
      , graphics.offset.rotation
      )
  }

  if (offsetRotation != null) {
    const newRotation = quat.multiply(
      quat.create()
    , rotation
    , offsetRotation
    )
    graphics.offset.position = vec3.add(
      vec3.create()
    , graphics.offset.position
    , vec3.scaleAndAdd(
        vec3.create()
      , vec3.transformQuat(vec3.create(), center, graphics.offset.rotation)
      , vec3.transformQuat(vec3.create(), center, newRotation             )
      , -1
      )
    )
    graphics.offset.rotation = newRotation
  }

  if (!vetoButtons && buttons.length >= 5 && buttons[4].pressed) {
    lastButton = now
    graphics.manager.current = Math.max(minFrame, graphics.manager.current - 1)
  }

  if (!vetoButtons && buttons.length >= 6 && buttons[5].pressed) {
    lastButton = now
    graphics.manager.current = Math.min(maxFrame, graphics.manager.current + 1)
  }

  if (!vetoButtons && buttons.length >= 4 && buttons[3].pressed) {
    lastButton = now
    graphics.offset.position = x.initialOffset.position
    graphics.offset.rotation = x.initialOffset.rotation
    offsetRotation = null
  }

  if (true)
    // FIXME: Only works for rotations.
    graphics.tool.position = vec3.add(
      vec3.create()
    , vec3.transformQuat(
        vec3.create()
      , vec3.scaleAndAdd(
          vec3.create()
        , vec3.add(vec3.create(), position, delta)
        , center
        , -1
        )
      , quat.invert(quat.create(), graphics.offset.rotation)
      )
    , center
    )
  else
    // FIXME: Only works for translations.
    graphics.tool.position = vec3.scaleAndAdd(
      vec3.create()
    , vec3.add(vec3.create(), position, delta)
    , graphics.offset.position
    , -1
    )

  graphics.tool.rotation = quat.multiply(
    quat.create()
  , quat.multiply(
      quat.create()
    , rotation
    , quat.fromValues(-0.271, -0.653, 0.271, 0.653)
    )
  , quat.invert(
      quat.create()
    , graphics.offset.rotation
    )
  )

  if (DEBUG) {
    let line = "interpretWebXR"
    for (const x of inputSource.gamepad.buttons)
      line = line + " " + x.pressed
    for (const x of inputSource.gamepad.axes)
      line = line + " " + x
    console.debug(line)
  }

  return true
}
