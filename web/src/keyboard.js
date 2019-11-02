
"use strict";


const Rendering = {
  Frames : require("./rendering/frames")
, Linear : require("./rendering/linear")
}

require("./gl-matrix")


const quat = glMatrix.quat
const vec3 = glMatrix.vec3


const DEBUG = true


const center = vec3.fromValues(0.5, 0.5, 0.5)


const x = {
  nextFrame              : "+"
, previousFrame          : "-"
, setFrames              : {1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6, 7: 7, 8: 8, 9: 9}
, offset                 : {shift: false}
, tool                   : {shift: true }
, deltaOffsetPosition    : 0.02
, deltaToolPosition      : 0.01
, deltaRotation          : 1.0
, move                   : {
                             ArrowRight: [vec3.fromValues( 1,  0,  0), vec3.fromValues( 0,  0,  0)]
                           , ArrowLeft : [vec3.fromValues(-1,  0,  0), vec3.fromValues( 0,  0,  0)]
                           , ArrowUp   : [vec3.fromValues( 0,  0, -1), vec3.fromValues( 0,  0,  0)]
                           , ArrowDown : [vec3.fromValues( 0,  0,  1), vec3.fromValues( 0,  0,  0)]
                           , PageUp    : [vec3.fromValues( 0,  1,  0), vec3.fromValues( 0,  0,  0)]
                           , PageDown  : [vec3.fromValues( 0, -1,  0), vec3.fromValues( 0,  0,  0)]
                           , k         : [vec3.fromValues( 0,  0,  0), vec3.fromValues( 1,  0,  0)]
                           , j         : [vec3.fromValues( 0,  0,  0), vec3.fromValues(-1,  0,  0)] 
                           , u         : [vec3.fromValues( 0,  0,  0), vec3.fromValues( 0,  1,  0)]
                           , n         : [vec3.fromValues( 0,  0,  0), vec3.fromValues( 0, -1,  0)]
                           , h         : [vec3.fromValues( 0,  0,  0), vec3.fromValues( 0,  0,  1)]
                           , l         : [vec3.fromValues( 0,  0,  0), vec3.fromValues( 0,  0, -1)]
                           }
, resetOffset            : '.'
, resetTool              : ','
, initialOffset          : {position: vec3.fromValues( 0  , 0  , 0  ), rotation: quat.fromValues(0, 0, 0, 1)}
, initialTool            : {position: vec3.fromValues(-0.1, 0.5, 0.5), rotation: quat.fromValues(0, 0, 0, 1)}
}


function interpret(y, graphics) {

  const key   = y.key
  const shift = y.shift

  if (DEBUG) console.log("interpret: key =", key, ", shift =", shift)

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

  const frames = Rendering.Frames.listFrames(graphics.manager)
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
    if (DEBUG) console.log("interpret: target =", target)
    const rotation = Rendering.Linear.fromEulerd(
      vec3.scale(
        vec3.create()
      , x.move[key][1]
      , deltaRotation
      )
    )
    target.position = vec3.add(
      vec3.create()
    , vec3.scaleAndAdd(
        vec3.create()
      , target.position
      , x.move[key][0]
      , deltaPosition
      )
    , vec3.scaleAndAdd(
        vec3.create()
      , center
      , vec3.transformQuat(vec3.create(), center, rotation)
      , -1
      )
    )
    target.rotation = quat.multiply(
      quat.create()
    , target.rotation
    , rotation
    )
    if (DEBUG) console.log("interpret: target' =", target)
  }

}


module.exports = {
  interpret: interpret
}
