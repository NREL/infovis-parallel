
import * as Frames     from "../rendering/frames"
import * as Linear     from "../rendering/linear"
import * as Navigation from "../navigation"


const quat = glMatrix.quat
const vec3 = glMatrix.vec3


const DEBUG = false


const zero = vec3.fromValues(0, 0, 0)

const center = vec3.fromValues(0.5, 0.5, 0.5)


export function interpret(y, graphics) {

  const x = Navigation.x
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

  else if (key == x.resetOffset) graphics.offset = {...x.initialOffset}

  else if (key == x.resetTool)
    graphics.tool = {...x.initialTool}

  else if ((target != null) && (key in x.move)) {
    if (target == graphics.tool)
      Navigation.updateTool(
        graphics
      , vec3.scale(vec3.create(), x.move[key][0], deltaPosition)
      , vec3.scale(vec3.create(), x.move[key][1], deltaRotation)
      )
    else
      Navigation.updateOffset(
        graphics
      , vec3.scale(vec3.create(), x.move[key][0], deltaPosition)
      , vec3.scale(vec3.create(), x.move[key][1], deltaRotation)
      )
  }

}
