
import * as Frames     from "../rendering/frames"
import * as Linear     from "../rendering/linear"
import * as Navigation from "../navigation"


const quat = glMatrix.quat
const vec3 = glMatrix.vec3


const DEBUG = false


const zero = vec3.fromValues(0, 0, 0)

const center = vec3.fromValues(0.5, 0.5, 0.5)


let gamepad = null

let toolMode = false

let started = false

let lastButton = null


window.addEventListener("gamepadconnected", function(e) {
  if (e.gamepad.buttons.length < 12 || e.gamepad.axes.length < 8)
    return
  gamepad = e.gamepad
  if (DEBUG)
    console.debug("Connected to gamepad %s.", gamepad.id)
})


window.addEventListener("gamepaddisconnected", function(e) {
  if (DEBUG)
    console.debug("Disconnecting from gamepad %s.", gamepad.id)
  gamepad = null
})


export function reset() {
  started = false
  lastButton = Date.now()
}


export function interpret(graphics) {

  const x = Navigation.x
  const result = {dirty: false, depressed: 0, analog: []}

  const gamepads = navigator.getGamepads()
  if (gamepad == null || gamepads.length <= gamepad.index || gamepads[gamepad.index].id != gamepad.id)
    return result
  gamepad = gamepads[gamepad.index]

  const now = Date.now()
  const vetoPeriod = 300
  const vetoButtons = now - lastButton <= vetoPeriod

  const startPeriod = 3000
  if (!started) {
    if (now - lastButton > startPeriod)
      started = true
    else
      return result
  }

  for (let i = 0; i < gamepad.buttons.length; ++i)
    result.depressed |= gamepad.buttons[i].pressed << i
  result.analog = gamepad.axes
  result.dirty = true

  const frames = Frames.listFrames(graphics.manager)
  const minFrame = frames.length == 0 ? 0 : Math.min(...frames)
  const maxFrame = frames.length == 0 ? 0 : Math.max(...frames)

  if (!vetoButtons && gamepad.buttons[6].pressed) { // L1 button
    graphics.manager.current = Math.max(graphics.manager.current - 1, minFrame)
    lastButton = now
    result.dirty = true
  }

  if (!vetoButtons && gamepad.buttons[7].pressed) { // R1 button
    graphics.manager.current = Math.min(graphics.manager.current + 1, maxFrame)
    lastButton = now
    result.dirty = true
  }

  if (!vetoButtons && gamepad.buttons[8].pressed) { // select button
    toolMode = !toolMode
    lastButton = now
  }

  if (!vetoButtons && gamepad.buttons[9].pressed) { // start button
    if (toolMode)
      graphics.tool = {...x.initialTool}
    else
      graphics.offset = {...x.initialOffset}
    lastButton = now
    result.dirty = true
  }

  const retardation = 0.75
  const scalePosition = retardation * (toolMode ? x.deltaToolPosition : x.deltaOffsetPosition)
  const scaleRotation = retardation * x.deltaRotation

  let deltaPosition = vec3.scale(vec3.create(), vec3.fromValues(
      gamepad.axes[2] // right on right joystick
  , - gamepad.axes[1] // towards on left joystick
  ,   gamepad.axes[3] // towards on right joystick
  ), scalePosition)

  let deltaRotation = vec3.scale(vec3.create(), vec3.fromValues(
      gamepad.axes[7] // towards on d-pad
  ,   gamepad.axes[6] // right on d-pad
  , - gamepad.axes[0] // right on left joystick
  ), scaleRotation)

  if (vec3.equals(deltaPosition, zero) && vec3.equals(deltaRotation, zero))
    return result

  if (toolMode)
    Navigation.updateTool(
      graphics
    , deltaPosition
    , deltaRotation
    , graphics.offset.rotation
    )
  else
    Navigation.updateOffset(
      graphics
    , deltaPosition
    , deltaRotation
    )

  result.dirty = true
  return result

}
