
require("../gl-matrix")


const mat4 = glMatrix.mat4


vertexShaderSource = `#version 300 es

uniform mat4 projection_modelview;

in vec3 mesh_position;

in vec3 instance_position;
in vec3 instance_scale   ;
in vec4 instance_rotation;
in uint instance_color   ;

out vec4 vColor;

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


fragmentShaderSource = `#version 300 es

precision mediump float;

in  vec4 vColor  ;
out vec4 outColor;

void main(void) {
  outColor = vColor;
}`


function prepareShapeProgram(gl) {

  const vertexShader = gl.createShader(gl.VERTEX_SHADER)
  gl.shaderSource(vertexShader, vertexShaderSource)
  gl.compileShader(vertexShader)
  const vertexSuccess = gl.getShaderParameter(vertexShader, gl.COMPILE_STATUS)
  if (!vertexSuccess)
    throw "Could not compile vertex shader:" + gl.getShaderInfoLog(vertexShader)

  const fragmentShader = gl.createShader(gl.FRAGMENT_SHADER)
  gl.shaderSource(fragmentShader, fragmentShaderSource)
  gl.compileShader(fragmentShader)
  const fragmentSuccess = gl.getShaderParameter(fragmentShader, gl.COMPILE_STATUS)
  if (!fragmentSuccess)
    throw "Could not compile fragment shader: " + gl.getShaderInfoLog(fragmentShader)

  const program = gl.createProgram()
  gl.attachShader(program, vertexShader  )
  gl.attachShader(program, fragmentShader)
  gl.linkProgram(program)
  const programSuccess = gl.getProgramParameter(program, gl.LINK_STATUS);
  if (!programSuccess)
    throw "Could not link program: " + gl.getProgramInfoLog(program)

  return {
    program              : program
  , pmvLocation          : gl.getUniformLocation(program, "projection_modelview")
  , meshLocation         : gl.getAttribLocation (program, "mesh_position"       )
  , positionsLocation    : gl.getAttribLocation (program, "instance_position"   )
  , rotationsLocation    : gl.getAttribLocation (program, "instance_rotation"   )
  , scalesLocation       : gl.getAttribLocation (program, "instance_scale"      )
  , colorsLocation       : gl.getAttribLocation (program, "instance_color"      )
  , meshDescription      : {size: 3, isFloat: true , stride: 12}
  , positionsDescription : {size: 3, isFloat: true , stride: 12}
  , rotationsDescription : {size: 4, isFloat: true , stride: 16}
  , scalesDescription    : {size: 3, isFloat: true , stride: 12}
  , colorsDescription    : {size: 1, isFloat: false, stride:  4}
  }

}


function selectShapeProgram(gl, shapeProgram) {
  gl.useProgram(shapeProgram == null ? null : shapeProgram.program)
}


function setProjectionModelView(gl, shapeProgram, projection, modelView) {
  const matrx = makeMatrix(projection, modelView)
  gl.uniformMatrix4fv(shapeProgram.pmvLocation, false, matrx)
}


function makeMatrix(gl, projection, modelView) {
  return mat4.multiply(mat4.create(), projection, modelView)
}


function bindMesh(gl, shapeProgram, bufferObject) {
  bindAttributes(gl, false, shapeProgram.meshLocation, shapeProgram.meshDescription, bufferObject)
}


function bindPositions(gl, shapeProgram, bufferObject) {
  bindAttributes(gl, true, shapeProgram.positionsLocation, shapeProgram.positionsDescrption, bufferObject)
}


function bindRotations(gl, shapeProgram, bufferObject) {
  bindAttributes(gl, true, shapeProgram.rotationsLocation, shapeProgram.rotationsDescription, bufferObject)
}


function bindScales(gl, shapeProgram, bufferObject) {
  bindAttributes(gl, true, shapeProgram.scalesLocation, shapeProgram.scalesDescription, bufferObject)
}


function bindColors(gl, shapeProgram, bufferObject) {
  bindAttributes(gl, true, shapeProgram.colorsLocation, shapeProgram.colorsDescription, bufferObject)
}


function bindAttributes(gl, instanced, location, description, buffer) {
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer)
  gl.vertexAttribPointer(
    location
  , description.numComponents
  , gl.FLOAT
  , !description.isFloat
  , description.stride
  , 0
  )
  if (instanced)
    gl.vertexAttribDivisor(location, 1)
  gl.enableVertexAttribArray(location)
  // FIXME: Do we need to unbind?
//gl.bindBuffer(gl.ARRAY_BUFFER, null)
}

function unbindAttributes(gl, location) {
  gl.disableVertexAttribArray(location)
}


module.exports = {
  prepareShapeProgram     : prepareShapeProgram
, selectShapeProgram      : selectShapeProgram
, setProjectionModelView  : setProjectionModelView
, bindMesh                : bindMesh
, bindPositions           : bindPositions
, bindRotations           : bindRotations
, bindScales              : bindScales
, bindColors              : bindColors
}
