
'use strict';


require("../gl-matrix")


const mat4 = glMatrix.mat4


const DEBUG = false


const vertexShaderSource = `#version 300 es

uniform mat4 projection_modelview;

in vec3 mesh_position;

in vec3 instance_position;
in vec4 instance_rotation;
in vec3 instance_scale   ;
in uint instance_color   ;

flat out vec4 vColor;

vec3 rotate(vec3 p, vec4 q) {
  return p + 2. * cross(q.xyz, cross(q.xyz, p) + q.w * p);
}

void main() {
  vec4 position = vec4(rotate(mesh_position * instance_scale, instance_rotation) + instance_position, 1);
  gl_Position = projection_modelview * position;
  vColor = vec4(float((0xFF000000u & instance_color) >> 24) / 255.,
                float((0x00FF0000u & instance_color) >> 16) / 255.,
                float((0x0000FF00u & instance_color) >>  8) / 255.,
                float( 0x000000FFu & instance_color       ) / 255.);
}`


const fragmentShaderSource = `#version 300 es

precision highp float;

flat in vec4 vColor;
out vec4 color;

void main(void) {
  if (vColor.a == 0.)
    discard;
  color = vColor;
}`


function compileAndLink(gl, vertexShader, fragmentShader) {

  function makeShader(name, type, source) {
    const shader = gl.createShader(type)
    gl.shaderSource(shader, source)
    gl.compileShader(shader)
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS))
      throw new Error("Could not compile " + name + " shader:" + gl.getShaderInfoLog(shader))
    return shader
  }

  const program = gl.createProgram()
  gl.attachShader(program, makeShader("vertex"  , gl.VERTEX_SHADER  , vertexShader  ))
  gl.attachShader(program, makeShader("fragment", gl.FRAGMENT_SHADER, fragmentShader))
  gl.linkProgram(program)
  if (!gl.getProgramParameter(program, gl.LINK_STATUS))
    throw new Error("Could not link program: " + gl.getProgramInfoLog(program))

  return program
}


function prepareShapeProgram(gl) {
  const program = compileAndLink(gl, vertexShaderSource, fragmentShaderSource)
  return {
    program              : program
  , pmvLocation          : gl.getUniformLocation(program, "projection_modelview")
  , meshLocation         : gl.getAttribLocation (program, "mesh_position"       )
  , positionsLocation    : gl.getAttribLocation (program, "instance_position"   )
  , rotationsLocation    : gl.getAttribLocation (program, "instance_rotation"   )
  , scalesLocation       : gl.getAttribLocation (program, "instance_scale"      )
  , colorsLocation       : gl.getAttribLocation (program, "instance_color"      )
  , meshDescription      : {components: 3, isFloat: true }
  , positionsDescription : {components: 3, isFloat: true }
  , rotationsDescription : {components: 4, isFloat: true }
  , scalesDescription    : {components: 3, isFloat: true }
  , colorsDescription    : {components: 1, isFloat: false}
  }

}


function selectShapeProgram(gl, shapeProgram) {
  if (DEBUG) console.debug("selectShapeProgram")
  gl.useProgram(shapeProgram == null ? null : shapeProgram.program)
}


function setProjectionModelView(gl, shapeProgram, projection, modelView) {

  const pmv = mat4.multiply(mat4.create(), projection, modelView)

  gl.uniformMatrix4fv(shapeProgram.pmvLocation, false, pmv)

  if (DEBUG) console.debug("setProjectionModelView: projection =", projection)
  if (DEBUG) console.debug("setProjectionModelView: modelView =" , modelView )
  if (DEBUG) console.debug("setProjectionModelView: pmv ="       , pmv       )

  return pmv
}


function bindMesh(gl, shapeProgram, bufferObject) {
  if (DEBUG) console.debug("bindMesh: meshDescription =", shapeProgram.meshDescription)
  bindAttributes(gl, false, shapeProgram.meshLocation, shapeProgram.meshDescription, bufferObject)
}


function bindPositions(gl, shapeProgram, bufferObject) {
  if (DEBUG) console.debug("bindPositions: meshDescription =", shapeProgram.positionsDescription)
  bindAttributes(gl, true, shapeProgram.positionsLocation, shapeProgram.positionsDescription, bufferObject)
}


function bindRotations(gl, shapeProgram, bufferObject) {
  if (DEBUG) console.debug("bindRotations: meshDescription =", shapeProgram.rotationsDescription)
  bindAttributes(gl, true, shapeProgram.rotationsLocation, shapeProgram.rotationsDescription, bufferObject)
}


function bindScales(gl, shapeProgram, bufferObject) {
  if (DEBUG) console.debug("bindScales: meshDescription =", shapeProgram.scalesDescription)
  bindAttributes(gl, true, shapeProgram.scalesLocation, shapeProgram.scalesDescription, bufferObject)
}


function bindColors(gl, shapeProgram, bufferObject) {
  if (DEBUG) console.debug("bindColors: meshDescription =", shapeProgram.colorsDescription)
  bindAttributes(gl, true, shapeProgram.colorsLocation, shapeProgram.colorsDescription, bufferObject)
}


function bindAttributes(gl, instanced, location, description, buffer) {

  const byteCount = 4 // 32-bit elements.

  gl.bindBuffer(gl.ARRAY_BUFFER, buffer)

  gl.enableVertexAttribArray(location)

  if (description.isFloat)
    gl.vertexAttribPointer (location, description.components, gl.FLOAT, false, description.components * byteCount, 0)
  else
    gl.vertexAttribIPointer(location, description.components, gl.UNSIGNED_INT, description.components * byteCount, 0)

  if (instanced)
    gl.vertexAttribDivisor(location, 1)

  gl.bindBuffer(gl.ARRAY_BUFFER, null)

}


module.exports = {
  compileAndLink         : compileAndLink
, prepareShapeProgram    : prepareShapeProgram
, selectShapeProgram     : selectShapeProgram
, setProjectionModelView : setProjectionModelView
, bindMesh               : bindMesh
, bindPositions          : bindPositions
, bindRotations          : bindRotations
, bindScales             : bindScales
, bindColors             : bindColors
}
