
import * as Frames from "./rendering/frames"
import * as Linear from "./rendering/linear"


const quat = glMatrix.quat
const vec3 = glMatrix.vec3


const DEBUG = false


const zero = vec3.fromValues(0, 0, 0)

const center = vec3.fromValues(0.5, 0.5, 0.5)


export const x = {
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


export function updateOffset(graphics, deltaPosition, deltaRotation) {

  if (DEBUG) console.debug("updateOffset: graphics.offset =", graphics.offset)

  const oldRotation = graphics.offset.rotation
  const incrementalRotation = Linear.fromEulerd(deltaRotation)

  const newRotation = quat.multiply(
    quat.create()
  , incrementalRotation
  , oldRotation
  )

  graphics.offset.position = vec3.add(
    vec3.create()
  , vec3.add(
      vec3.create()
    , graphics.offset.position
    , deltaPosition
    )
  , vec3.scaleAndAdd(
      vec3.create()
    , vec3.transformQuat(vec3.create(), center, oldRotation)
    , vec3.transformQuat(vec3.create(), center, newRotation)
    , -1
    )
  )

  graphics.offset.rotation = newRotation

  if (DEBUG) console.debug("updateOffset: graphics.offset' =", graphics.offset)

}


export function updateTool(graphics, deltaPosition, deltaRotation) {

  if (DEBUG) console.debug("updateTool: graphics.tool =", graphics.tool)

  const oldRotation = graphics.tool.rotation
  const incrementalRotation = Linear.fromEulerd(deltaRotation)

  const newRotation = quat.multiply(
    quat.create()
  , quat.multiply(
      quat.create()
    , quat.multiply(
        quat.create()
      , quat.invert(
          quat.create()
        , graphics.offset.rotation
        )
      , incrementalRotation
      )
    , graphics.offset.rotation
    )
  , oldRotation
  )

  graphics.tool.position = vec3.add(
    vec3.create()
  , graphics.tool.position
  , vec3.transformQuat(
      vec3.create()
    , deltaPosition
    , quat.invert(
        quat.create()
      , graphics.offset.rotation
      )
    )
  )

  graphics.tool.rotation = newRotation

  if (DEBUG) console.debug("updateTool: graphics.tool' =", graphics.tool)

}
