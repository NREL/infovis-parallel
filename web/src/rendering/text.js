
'use strict'


const Program = require("./program")

require("../gl-matrix")


const mat4 = glMatrix.mat4
const vec3 = glMatrix.vec3


const DEBUG = true


function makePixmap(
  text
, textColor       = DEBUG ? "white" : "#FFFF0080" // CSS color
, textHeight      = 50                            // px
, fontFamily      = "monospace"                   // CSS font
, backgroundColor = DEBUG ? "gray"  : "#FFFFFF00" // CSS color
) {

  const ctx = uiTexture.getContext("2d")
  ctx.font = textHeight + "px " + fontFamily

  const width  = ctx.measureText(text).width
  const height = textHeight

  uiTexture.width  = width
  uiTexture.height = height

  ctx.fillStyle = backgroundColor
  ctx.fillRect(0, 0, width, height)

  ctx.font = textHeight + "px " + fontFamily
  ctx.textAlign = "left"
  ctx.textBaseline = "middle"
  ctx.fillStyle = textColor
  ctx.fillText(text, 0, height / 2)

  return ctx.getImageData(0, 0, width, height)

}


const vertexShaderSource = `#version 300 es

uniform mat4 projection_modelview;

in vec3 position;
in vec2 texture ;

flat out vec2 vTexture;

void main(void) {
  gl_Position = projection_modelview * vec4(position, 1.);
  vTexture = texture;
}`


const fragmentShaderSource = `#version 300 es

precision highp float;

uniform sampler2D sampler;

flat in vec2 vTexture;
out vec4 color;

void main(void) {
  color = texture(sampler, vTexture);
}`


let theShaders = null


function ensureShaders(gl) {

  if (theShaders != null)
    return

  theShaders = {}

  theShaders.program = Program.compileAndLink(gl, vertexShaderSource, fragmentShaderSource)
  gl.useProgram(theShaders.program)

  theShaders.pmvUniform     = gl.getUniformLocation(theShaders.program, "projection_modelview")
  theShaders.samplerUniform = gl.getUniformLocation(theShaders.program, "sampler"             )

  theShaders.positionAttribute = gl.getAttribLocation(theShaders.program, "position")
  theShaders.textureAttribute  = gl.getAttribLocation(theShaders.program, "texture" )

  gl.enableVertexAttribArray(theShaders.positionAttribute)
  gl.enableVertexAttribArray(theShaders.textureAttribute )

  theShaders.positionBuffer = gl.createBuffer()
  gl.bindBuffer(gl.ARRAY_BUFFER, theShaders.positionBuffer)
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
    -1., -1.,  0.
  ,  1., -1.,  0.
  ,  1.,  1.,  0.
  , -1.,  1.,  0.
  ]), gl.DYNAMIC_DRAW)

  theShaders.textureBuffer = gl.createBuffer()
  gl.bindBuffer(gl.ARRAY_BUFFER, theShaders.textureBuffer)
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
    0., 0.
  , 1., 0.
  , 1., 1.
  , 0., 1.
  ]), gl.STATIC_DRAW)

  theShaders.indexBuffer = gl.createBuffer()
  gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, theShaders.indexBuffer)
  gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, new Uint16Array([
    0, 1, 2
  , 0, 2, 3
  , 0, 3, 2
  , 0, 2, 1
  ]), gl.STATIC_DRAW)

  theShaders.texture = gl.createTexture()

}


function drawText(gl, imageData, points, size, perspective, modelView) {

    const pmv = mat4.multiply(mat4.create(), perspective, modelView)

    const size1 = size / imageData.height * imageData.width

    const o = vec3.fromValues(points[0][0], points[0][1], points[0][2])
    const h = vec3.fromValues(points[1][0], points[1][1], points[1][2])
    const v = vec3.fromValues(points[2][0], points[2][1], points[2][2])

    const oh = vec3.scale(vec3.create(), vec3.normalize(vec3.create(), vec3.scaleAndAdd(vec3.create(), h, o, -1)), size1)
    const ov = vec3.scale(vec3.create(), vec3.normalize(vec3.create(), vec3.scaleAndAdd(vec3.create(), v, o, -1)), size )

    const h1 = vec3.add(vec3.create(), o, oh)
    const v1 = vec3.add(vec3.create(), o, ov)
    const c  = vec3.add(vec3.create(), o, vec3.add(vec3.create(), oh, ov))

    const corners = [
       o[0],  o[1],  o[2]
    , h1[0], h1[1], h1[2]
    ,  c[0] , c[1],  c[2]
    , v1[0], v1[1], v1[2]
    ]

    if (DEBUG) console.debug("drawText: corners =", corners, ", imageData =", imageData)

    ensureShaders(gl)

    gl.bindBuffer(gl.ARRAY_BUFFER, theShaders.positionBuffer)
    gl.bufferSubData(gl.ARRAY_BUFFER, 0, new Float32Array(corners))
    gl.vertexAttribPointer(theShaders.positionAttribute, 3, gl.FLOAT, false, 0, 0)
    gl.enableVertexAttribArray(theShaders.positionAttribute)

    gl.bindBuffer(gl.ARRAY_BUFFER, theShaders.textureBuffer)
    gl.vertexAttribPointer(theShaders.textureAttribute, 2, gl.FLOAT, false, 0, 0)
    gl.enableVertexAttribArray(theShaders.textureAttribute)

    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, theShaders.indexBuffer)

    gl.useProgram(theShaders.program)

    gl.uniformMatrix4fv(theShaders.pmvUniform, false, pmv)
    gl.uniform1i(theShaders.samplerUniform   , 0         )

    gl.activeTexture(gl.TEXTURE0)

    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true)

    gl.bindTexture(gl.TEXTURE_2D, theShaders.texture)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, imageData)
    // FIXME: Experiment with these texture parameters.
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_NEAREST)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.generateMipmap(gl.TEXTURE_2D)

    gl.drawElements(gl.TRIANGLES, 12, gl.UNSIGNED_SHORT, 0)

}


module.exports = {
  makePixmap : makePixmap
, drawText   : drawText
}
