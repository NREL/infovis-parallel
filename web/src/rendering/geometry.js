
import * as Linear     from "./linear"

const vec3 = glMatrix.vec3


export const GLYPH_Cube     = 0
export const GLYPH_Sphere   = 1

export const GLYPH_Box      = 0
export const GLYPH_Cylinder = 1


export function defaultGeometry() {
  return {
    shape: {
      points: []
    , glyph : GLYPH_Cube
    }
  , size : 0
  , color: 0
  , text : ""
  }
}


const MASK_Posn =  1
const MASK_Size =  2
const MASK_Colr =  4
const MASK_Text =  8
const MASK_Glyp = 16


export function deltaPosition(deltaGeometry) {
  return (deltaGeometry.getMask() & MASK_Posn) != 0
}

export function deltaSize(deltaGeometry) {
  return (deltaGeometry.getMask() & MASK_Size) != 0
}

export function deltaColor(deltaGeometry) {
  return (deltaGeometry.getMask() & MASK_Colr) != 0
}

export function deltaText(deltaGeometry) {
  return (deltaGeometry.getMask() & MASK_Text) != 0
}

export function deltaGlyph(deltaGeometry) {
  return (deltaGeometry.getMask() & MASK_Glyp) != 0
}


export const GEOMETRY_Points     = 1
export const GEOMETRY_Polylines  = 2
export const GEOMETRY_Rectangles = 3
export const GEOMETRY_Label      = 4
export const GEOMETRY_Axis       = 5


export function merge(geometry, deltaGeometry) {

  const mask = deltaGeometry.getMask()

  if ((mask & MASK_Posn) != 0) {

    const posx = deltaGeometry.getPosxList()
    const posy = deltaGeometry.getPosyList()
    const posz = deltaGeometry.getPoszList()

    switch (deltaGeometry.getType()) {

      case GEOMETRY_Points:
        {
          const pointses = []
          let i = 0
          deltaGeometry.getCntsList().forEach(function(n) {
            const points = []
            for (let j = 0; j < n; ++j)
              points.push(vec3.fromValues(posx[i], posy[i], posz[i++]))
            pointses.push(points)
          })
          geometry.shape = {
            points: pointses
          , glyph : ("glyph" in geometry.shape) ? geometry.shape.glyph : GLYPH_Cube
          }
          break
        }

      case GEOMETRY_Polylines:
        {
          const polylines = []
          let i = 0
          deltaGeometry.getCntsList().forEach(function(n) {
            const polyline = []
            for (let j = 0; j < n; ++j)
              polyline.push(vec3.fromValues(posx[i], posy[i], posz[i++]))
            polylines.push(polyline)
          })
          geometry.shape = {
            polylines: polylines
//        , glyph    : ("glyph" in geometry.shape) ? geometry.shape.glyph : GLYPH_Cube
          }
          break
        }

      case GEOMETRY_Rectangles:
        {
          const rectangles = []
          let i = 0
          deltaGeometry.getCntsList().forEach(function(n) {
            rectangles.push([
              vec3.fromValues(posx[i], posy[i], posz[i++])
            , vec3.fromValues(posx[i], posy[i], posz[i++])
            , vec3.fromValues(posx[i], posy[i], posz[i++])
            ])
          })
          geometry.shape = {
            rectangles: rectangles
          }
          break
        }

      case GEOMETRY_Label:
        {
          geometry.shape = {
            label: [
              vec3.fromValues(posx[0], posy[0], posz[0])
            , vec3.fromValues(posx[1], posy[1], posz[1])
            , vec3.fromValues(posx[2], posy[2], posz[2])
            ]
          }
          break
        }

      case GEOMETRY_Axis:
        {
          geometry.shape = {
            axis: [
              vec3.fromValues(posx[0], posy[0], posz[0])
            , vec3.fromValues(posx[1], posy[1], posz[1])
            ]
          }
          break
        }

    }

  }

  if ((mask & MASK_Size) != 0)
    geometry.size = deltaGeometry.getSize()

  if ((mask & MASK_Colr) != 0)
    geometry.color = deltaGeometry.getColr()

  if ((mask & MASK_Text) != 0)
    geometry.text = deltaGeometry.getText()

  if ((mask & MASK_Glyp) != 0 && (("points" in geometry.shape) || ("polylines" in geometry.shape)))
    geometry.shape.glyph = deltaGeometry.getGlyp()

}


export function hasAxis(geometry) {
  return "axis" in geometry.shape
}


export function hasLabel(geometry) {
  return "label" in geometry.shape
}


export function hasPoints(geometry) {
  return "points" in geometry.shape
}


export function hasPolylines(geometry) {
  return "polylines" in geometry.shape
}


export function hasRectangles(geometry) {
  return "rectangles" in geometry.shape
}


export function distance(geometry, origin) {

  let dist = Number.MAX_VALUE

  if (hasPoints(geometry)) {

    geometry.shape.points.forEach(pointses => pointses.forEach(point => {
      dist = Math.min(dist, Linear.distancePointSphere(origin, point, geometry.size / 2))
    }))

  } else if (hasPolylines(geometry)) {

    geometry.shape.polylines.map((polyline) => [
      polyline.slice(0, polyline.length - 1)
    , polyline.slice(1, polyline.length    )
    ]).forEach(([u0s, u1s]) =>
      u0s.map(function(u0, i) {
        const u1 = u1s[i]
        dist = Math.min(dist, Linear.distancePointCylinder(origin, u0, u1, geometry.size / 2))
    }))

  } else if (hasRectangles(geometry)) {

    geometry.shape.rectangles.forEach(function([o, u, v]) {
      dist = Math.min(dist, Linear.distancePointRectangle(origin, o, u, v))
    })

  } else if (hasLabel(geometry)) {

  } else if (hasAxis(geometry)) {

    const u0 = geometry.shape.axis[0]
    const u1 = geometry.shape.axis[1]
    dist = Math.min(dist, Linear.distancePointCylinder(origin, u0, u1, geometry.size / 2))

  }

  return dist

}
