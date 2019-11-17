
import * as Frames from "./rendering/frames"
import * as Linear from "./rendering/linear"


const quat = glMatrix.quat
const vec3 = glMatrix.vec3


const DEBUG = false


const zero = vec3.fromValues(0, 0, 0)

const center = vec3.fromValues(0.5, 0.5, 0.5)


const x = {
  nextFrame              : "+"
, previousFrame          : "-"
, setFrames              : {1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6, 7: 7, 8: 8, 9: 9}
, offset                 : {shift: false}
, tool                   : {shift: true }
, deltaOffsetPosition    : 0.0075
, deltaToolPosition      : 0.0075
, deltaRotation          : 0.5000
, move                   : {
                             ArrowRight: [vec3.fromValues( 1,  0,  0), vec3.fromValues( 0,  0,  0)]
                           , ArrowLeft : [vec3.fromValues(-1,  0,  0), vec3.fromValues( 0,  0,  0)]
                           , ArrowUp   : [vec3.fromValues( 0,  0, -1), vec3.fromValues( 0,  0,  0)]
                           , ArrowDown : [vec3.fromValues( 0,  0,  1), vec3.fromValues( 0,  0,  0)]
                           , PageUp    : [vec3.fromValues( 0,  1,  0), vec3.fromValues( 0,  0,  0)]
                           , PageDown  : [vec3.fromValues( 0, -1,  0), vec3.fromValues( 0,  0,  0)]
                           , k         : [vec3.fromValues( 0,  0,  0), vec3.fromValues( 1,  0,  0)]
                           , K         : [vec3.fromValues( 0,  0,  0), vec3.fromValues( 1,  0,  0)]
                           , j         : [vec3.fromValues( 0,  0,  0), vec3.fromValues(-1,  0,  0)] 
                           , J         : [vec3.fromValues( 0,  0,  0), vec3.fromValues(-1,  0,  0)] 
                           , u         : [vec3.fromValues( 0,  0,  0), vec3.fromValues( 0,  1,  0)]
                           , U         : [vec3.fromValues( 0,  0,  0), vec3.fromValues( 0,  1,  0)]
                           , n         : [vec3.fromValues( 0,  0,  0), vec3.fromValues( 0, -1,  0)]
                           , N         : [vec3.fromValues( 0,  0,  0), vec3.fromValues( 0, -1,  0)]
                           , h         : [vec3.fromValues( 0,  0,  0), vec3.fromValues( 0,  0,  1)]
                           , H         : [vec3.fromValues( 0,  0,  0), vec3.fromValues( 0,  0,  1)]
                           , l         : [vec3.fromValues( 0,  0,  0), vec3.fromValues( 0,  0, -1)]
                           , L         : [vec3.fromValues( 0,  0,  0), vec3.fromValues( 0,  0, -1)]
                           }
, resetOffset            : '.'
, resetTool              : ','
, initialOffset          : {position: vec3.fromValues( 0  , 0  , 0  ), rotation: quat.fromValues(0, 0, 0, 1)}
, initialTool            : {position: vec3.fromValues(-0.1, 0.5, 0.5), rotation: quat.fromValues(0, 0, 0, 1)}
}


export function interpretKeyboard(y, graphics) {

  const key   = y.key
  const shift = y.shift

  if (DEBUG) console.debug("interpret: key =", key, ", shift =", shift)

  let target = null
  let deltaPosition = 0
  let deltaRotation = x.deltaRotation
  if (shift == x.offset.shift) {
    target = graphics.offset
    deltaPosition = x.deltaOffsetPosition
  } else if (shift == x.tool.shift) {
    target = graphics.tool
    deltaPosition = x.deltaToolPosition
  }

  const frames = Frames.listFrames(graphics.manager)
  const minFrame = Math.min(...frames)
  const maxFrame = Math.max(...frames)

  if (key == x.nextFrame)
    graphics.manager.current = Math.min(graphics.manager.current + 1, maxFrame)

  else if (key == x.previousFrame)
    graphics.manager.current = Math.max(graphics.manager.current - 1, minFrame)

  else if (key in x.setFrames)
    graphics.manager.current = x.setFrames[key]

  else if (key == x.resetOffset)
    graphics.offset = {...x.initialOffset}

  else if (key == x.resetTool)
    graphics.tool = {...x.initialTool}

  else if ((target != null) && (key in x.move)) {
    if (target == graphics.tool)
      updateTool(
        target
      , vec3.scale(vec3.create(), x.move[key][0], deltaPosition)
      , vec3.scale(vec3.create(), x.move[key][1], deltaRotation)
      , graphics.offset.rotation
      )
    else
      updateOffset(
        target
      , vec3.scale(vec3.create(), x.move[key][0], deltaPosition)
      , vec3.scale(vec3.create(), x.move[key][1], deltaRotation)
      )
  }

}


let gamepad = null

let toolMode = false

let started = false

let lastButton = Date.now()


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


export function interpretGamepad(graphics) {

  const gamepads = navigator.getGamepads()
  if (gamepad == null || gamepads.length <= gamepad.index || gamepads[gamepad.index].id != gamepad.id)
    return true
  gamepad = gamepads[gamepad.index]

  const now = Date.now()
  const vetoPeriod = 300
  const vetoButtons = now - lastButton <= vetoPeriod

  const startPeriod = 3000
  if (!started) {
    if (now - lastButton > startPeriod)
      started = true
    else
      return false
  }
    
  const frames = Frames.listFrames(graphics.manager)
  const minFrame = Math.min(...frames)
  const maxFrame = Math.max(...frames)

  let dirty = false

  if (!vetoButtons && gamepad.buttons[7].pressed) { // right (R1) shoulder button
    graphics.manager.current = Math.min(graphics.manager.current + 1, maxFrame)
    lastButton = now
    dirty = true
  }

  if (!vetoButtons && gamepad.buttons[6].pressed) { // left (L1) shoulder button
    graphics.manager.current = Math.max(graphics.manager.current - 1, minFrame)
    lastButton = now
    dirty = true
  }

  if (!vetoButtons && gamepad.buttons[10].pressed) { // select button
    toolMode = !toolMode
    lastButton = now
  }

  if (!vetoButtons && gamepad.buttons[11].pressed) { // start button
    if (toolMode)
      graphics.tool = {...x.initialTool}
    else
      graphics.offset = {...x.initialOffset}
    lastButton = now
    dirty = true
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
    return dirty

  if (toolMode)
    updateTool(
      graphics.tool
    , deltaPosition
    , deltaRotation
    , graphics.offset.rotation
    )
  else
    updateOffset(
      graphics.offset
    , deltaPosition
    , deltaRotation
    )

  return true

}


function updateOffset(target, deltaPosition, deltaRotation) {

  if (DEBUG) console.debug("updateOffset: target =", target)

  const oldRotation = target.rotation
  const incrementalRotation = Linear.fromEulerd(deltaRotation)

  let newRotation = quat.multiply(
    quat.create()
  , incrementalRotation
  , oldRotation
  )

  target.position = vec3.add(
    vec3.create()
  , vec3.add(
      vec3.create()
    , target.position
    , deltaPosition
    )
  , vec3.scaleAndAdd(
      vec3.create()
    , vec3.transformQuat(vec3.create(), center, oldRotation)
    , vec3.transformQuat(vec3.create(), center, newRotation)
    , -1
    )
  )

  target.rotation = newRotation

  if (DEBUG) console.debug("updateOffset: target' =", target)

}


function updateTool(target, deltaPosition, deltaRotation, extraRotation) {

  if (DEBUG) console.debug("updateTool: target =", target)

  const oldRotation = target.rotation
  const incrementalRotation = Linear.fromEulerd(deltaRotation)

  let newRotation = quat.multiply(
    quat.create()
  , quat.multiply(
      quat.create()
    , quat.multiply(
        quat.create()
      , quat.invert(
          quat.create()
        , extraRotation
        )
      , incrementalRotation
      )
    , extraRotation
    )
  , oldRotation
  )

  target.position = vec3.add(
    vec3.create()
  , target.position
  , vec3.transformQuat(
      vec3.create()
    , deltaPosition
    , quat.invert(
        quat.create()
      , extraRotation
      )
    )
  )

  target.rotation = newRotation

  if (DEBUG) console.debug("updateTool: target' =", target)

}
