
'use strict'


// Based on <https://delphic.me.uk/tutorials/webgl-text>.

function makePixmap(
  text
, textColor       = "gray"      // CSS color
, textHeight      = 50          // px
, fontFamily      = "monospace" // CSS font
, backgroundColor = "#FFFFFF00" // CSS color
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

attribute vec3 aVertexPosition
attribute vec3 aVertexNormal
attribute vec2 aTextureCoord

uniform mat4 uMVMatrix
uniform mat4 uPMatrix
uniform mat3 uNMatrix

uniform vec3 uAmbientColor

uniform vec3 uLightingDirection
uniform vec3 uDirectionalColor

uniform bool uUseLighting

varying vec2 vTextureCoord
varying vec3 vLightWeighting

void main(void) {
  gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0)
  vTextureCoord = aTextureCoord

  if (!uUseLighting) {
    vLightWeighting = vec3(1.0, 1.0, 1.0)
  } else {
    vec3 transformedNormal = uNMatrix * aVertexNormal
    float directionalLightWeighting = max(dot(transformedNormal, uLightingDirection), 0.0)
    vLightWeighting = uAmbientColor + uDirectionalColor * directionalLightWeighting
  }
}`


const fragmentShaderSource = `#version 300 es

precision mediump float

varying vec2 vTextureCoord
varying vec3 vLightWeighting

uniform sampler2D uSampler

void main(void) {
    vec4 textureColor = texture2D(uSampler, vec2(vTextureCoord.s, vTextureCoord.t))
    gl_FragColor = vec4(textureColor.rgb * vLightWeighting, textureColor.a)
}`


/*
function getShader(gl, id) {
    var shaderScript = document.getElementById(id)
    if (!shaderScript) {
        return null
    }

    var str = ""
    var k = shaderScript.firstChild
    while (k) {
        if (k.nodeType == 3) {
            str += k.textContent
        }
        k = k.nextSibling
    }

    var shader
    if (shaderScript.type == "x-shader/x-fragment") {
        shader = gl.createShader(gl.FRAGMENT_SHADER)
    } else if (shaderScript.type == "x-shader/x-vertex") {
        shader = gl.createShader(gl.VERTEX_SHADER)
    } else {
        return null
    }

    gl.shaderSource(shader, str)
    gl.compileShader(shader)

    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
        alert(gl.getShaderInfoLog(shader))
        return null
    }

    return shader
}

var shaderProgram

function initShaders() {
    var fragmentShader = getShader(gl, "shader-fs")
    var vertexShader = getShader(gl, "shader-vs")

    shaderProgram = gl.createProgram()
    gl.attachShader(shaderProgram, vertexShader)
    gl.attachShader(shaderProgram, fragmentShader)
    gl.linkProgram(shaderProgram)

    if (!gl.getProgramParameter(shaderProgram, gl.LINK_STATUS)) {
        alert("Could not initialise shaders")
    }

    gl.useProgram(shaderProgram)

    shaderProgram.vertexPositionAttribute = gl.getAttribLocation(shaderProgram, "aVertexPosition")
    gl.enableVertexAttribArray(shaderProgram.vertexPositionAttribute)

    shaderProgram.vertexNormalAttribute = gl.getAttribLocation(shaderProgram, "aVertexNormal")
    gl.enableVertexAttribArray(shaderProgram.vertexNormalAttribute)

    shaderProgram.textureCoordAttribute = gl.getAttribLocation(shaderProgram, "aTextureCoord")
    gl.enableVertexAttribArray(shaderProgram.textureCoordAttribute)

    shaderProgram.pMatrixUniform = gl.getUniformLocation(shaderProgram, "uPMatrix")
    shaderProgram.mvMatrixUniform = gl.getUniformLocation(shaderProgram, "uMVMatrix")
    shaderProgram.nMatrixUniform = gl.getUniformLocation(shaderProgram, "uNMatrix")
    shaderProgram.samplerUniform = gl.getUniformLocation(shaderProgram, "uSampler")
    shaderProgram.useLightingUniform = gl.getUniformLocation(shaderProgram, "uUseLighting")
    shaderProgram.ambientColorUniform = gl.getUniformLocation(shaderProgram, "uAmbientColor")
    shaderProgram.lightingDirectionUniform = gl.getUniformLocation(shaderProgram, "uLightingDirection")
    shaderProgram.directionalColorUniform = gl.getUniformLocation(shaderProgram, "uDirectionalColor")
}

function handleLoadedTexture(texture, textureCanvas) {
    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true)

    gl.bindTexture(gl.TEXTURE_2D, texture)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, textureCanvas)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_NEAREST)
    gl.generateMipmap(gl.TEXTURE_2D)

    gl.bindTexture(gl.TEXTURE_2D, null)
}

var canvasTexture

function initTexture() {
    canvasTexture = gl.createTexture()
    handleLoadedTexture(canvasTexture, document.getElementById('textureCanvas'))
}

var mvMatrix = mat4.create()
var mvMatrixStack = []
var pMatrix = mat4.create()

function mvPushMatrix() {
    var copy = mat4.create()
    mat4.set(mvMatrix, copy)
    mvMatrixStack.push(copy)
}

function mvPopMatrix() {
    if (mvMatrixStack.length == 0) {
        throw "Invalid popMatrix!"
    }
    mvMatrix = mvMatrixStack.pop()
}

function setMatrixUniforms() {
    gl.uniformMatrix4fv(shaderProgram.pMatrixUniform, false, pMatrix)
    gl.uniformMatrix4fv(shaderProgram.mvMatrixUniform, false, mvMatrix)

    var normalMatrix = mat3.create()
    mat4.toInverseMat3(mvMatrix, normalMatrix)
    mat3.transpose(normalMatrix)
    gl.uniformMatrix3fv(shaderProgram.nMatrixUniform, false, normalMatrix)
}

function degToRad(degrees) {
    return degrees * Math.PI / 180
}

var xRot = 0
var xSpeed = 10

var yRot = 0
var ySpeed = -10

var z = -5.0

var cubeVertexPositionBuffer
var cubeVertexNormalBuffer
var cubeVertexTextureCoordBuffer
var cubeVertexIndexBuffer

function initBuffers() {
    cubeVertexPositionBuffer = gl.createBuffer()
    gl.bindBuffer(gl.ARRAY_BUFFER, cubeVertexPositionBuffer)
    vertices = [
        // Front face
        -1.0, -1.0,  1.0,
         1.0, -1.0,  1.0,
         1.0,  1.0,  1.0,
        -1.0,  1.0,  1.0,

        // Back face
        -1.0, -1.0, -1.0,
        -1.0,  1.0, -1.0,
         1.0,  1.0, -1.0,
         1.0, -1.0, -1.0,

        // Top face
        -1.0,  1.0, -1.0,
        -1.0,  1.0,  1.0,
         1.0,  1.0,  1.0,
         1.0,  1.0, -1.0,

        // Bottom face
        -1.0, -1.0, -1.0,
         1.0, -1.0, -1.0,
         1.0, -1.0,  1.0,
        -1.0, -1.0,  1.0,

        // Right face
         1.0, -1.0, -1.0,
         1.0,  1.0, -1.0,
         1.0,  1.0,  1.0,
         1.0, -1.0,  1.0,

        // Left face
        -1.0, -1.0, -1.0,
        -1.0, -1.0,  1.0,
        -1.0,  1.0,  1.0,
        -1.0,  1.0, -1.0,
    ]
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW)
    cubeVertexPositionBuffer.itemSize = 3
    cubeVertexPositionBuffer.numItems = 24

    cubeVertexNormalBuffer = gl.createBuffer()
    gl.bindBuffer(gl.ARRAY_BUFFER, cubeVertexNormalBuffer)
    var vertexNormals = [
        // Front face
         0.0,  0.0,  1.0,
         0.0,  0.0,  1.0,
         0.0,  0.0,  1.0,
         0.0,  0.0,  1.0,

        // Back face
         0.0,  0.0, -1.0,
         0.0,  0.0, -1.0,
         0.0,  0.0, -1.0,
         0.0,  0.0, -1.0,

        // Top face
         0.0,  1.0,  0.0,
         0.0,  1.0,  0.0,
         0.0,  1.0,  0.0,
         0.0,  1.0,  0.0,

        // Bottom face
         0.0, -1.0,  0.0,
         0.0, -1.0,  0.0,
         0.0, -1.0,  0.0,
         0.0, -1.0,  0.0,

        // Right face
         1.0,  0.0,  0.0,
         1.0,  0.0,  0.0,
         1.0,  0.0,  0.0,
         1.0,  0.0,  0.0,

        // Left face
        -1.0,  0.0,  0.0,
        -1.0,  0.0,  0.0,
        -1.0,  0.0,  0.0,
        -1.0,  0.0,  0.0
    ]
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertexNormals), gl.STATIC_DRAW)
    cubeVertexNormalBuffer.itemSize = 3
    cubeVertexNormalBuffer.numItems = 24

    cubeVertexTextureCoordBuffer = gl.createBuffer()
    gl.bindBuffer(gl.ARRAY_BUFFER, cubeVertexTextureCoordBuffer)
    var textureCoords = [
        // Front face
        0.0, 0.0,
        1.0, 0.0,
        1.0, 1.0,
        0.0, 1.0,

        // Back face
        1.0, 0.0,
        1.0, 1.0,
        0.0, 1.0,
        0.0, 0.0,

        // Top face
        0.0, 1.0,
        0.0, 0.0,
        1.0, 0.0,
        1.0, 1.0,

        // Bottom face
        1.0, 1.0,
        0.0, 1.0,
        0.0, 0.0,
        1.0, 0.0,

        // Right face
        1.0, 0.0,
        1.0, 1.0,
        0.0, 1.0,
        0.0, 0.0,

        // Left face
        0.0, 0.0,
        1.0, 0.0,
        1.0, 1.0,
        0.0, 1.0
    ]
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(textureCoords), gl.STATIC_DRAW)
    cubeVertexTextureCoordBuffer.itemSize = 2
    cubeVertexTextureCoordBuffer.numItems = 24

    cubeVertexIndexBuffer = gl.createBuffer()
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, cubeVertexIndexBuffer)
    var cubeVertexIndices = [
        0, 1, 2,      0, 2, 3,    // Front face
        4, 5, 6,      4, 6, 7,    // Back face
        8, 9, 10,     8, 10, 11,  // Top face
        12, 13, 14,   12, 14, 15, // Bottom face
        16, 17, 18,   16, 18, 19, // Right face
        20, 21, 22,   20, 22, 23  // Left face
    ]
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, new Uint16Array(cubeVertexIndices), gl.STATIC_DRAW)
    cubeVertexIndexBuffer.itemSize = 1
    cubeVertexIndexBuffer.numItems = 36
}

function drawScene() {
    gl.viewport(0, 0, gl.viewportWidth, gl.viewportHeight)
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

    mat4.perspective(45, gl.viewportWidth / gl.viewportHeight, 0.1, 100.0, pMatrix)

    mat4.identity(mvMatrix)

    mat4.translate(mvMatrix, [0.0, 0.0, z])

    mat4.rotate(mvMatrix, degToRad(xRot), [1, 0, 0])
    mat4.rotate(mvMatrix, degToRad(yRot), [0, 1, 0])

    gl.bindBuffer(gl.ARRAY_BUFFER, cubeVertexPositionBuffer)
    gl.vertexAttribPointer(shaderProgram.vertexPositionAttribute, cubeVertexPositionBuffer.itemSize, gl.FLOAT, false, 0, 0)

    gl.bindBuffer(gl.ARRAY_BUFFER, cubeVertexNormalBuffer)
    gl.vertexAttribPointer(shaderProgram.vertexNormalAttribute, cubeVertexNormalBuffer.itemSize, gl.FLOAT, false, 0, 0)

    gl.bindBuffer(gl.ARRAY_BUFFER, cubeVertexTextureCoordBuffer)
    gl.vertexAttribPointer(shaderProgram.textureCoordAttribute, cubeVertexTextureCoordBuffer.itemSize, gl.FLOAT, false, 0, 0)

    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, canvasTexture)
    gl.uniform1i(shaderProgram.samplerUniform, 0)
    var lighting = true
    gl.uniform1i(shaderProgram.useLightingUniform, lighting)
    if (lighting) {
        gl.uniform3f(shaderProgram.ambientColorUniform, 0.2, 0.2, 0.2)

        var lightingDirection = [ -0.25, -0.25, -1 ]
        var adjustedLD = vec3.create()
        vec3.normalize(lightingDirection, adjustedLD)
        vec3.scale(adjustedLD, -1)
        gl.uniform3fv(shaderProgram.lightingDirectionUniform, adjustedLD)
        gl.uniform3f(shaderProgram.directionalColorUniform, 0.8, 0.8, 0.8)
    }

    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, cubeVertexIndexBuffer)
    setMatrixUniforms()
    gl.drawElements(gl.TRIANGLES, cubeVertexIndexBuffer.numItems, gl.UNSIGNED_SHORT, 0)
}

var lastTime = 0

function animate() {
    var timeNow = new Date().getTime()
    if (lastTime != 0) {
        var elapsed = timeNow - lastTime

        xRot += (xSpeed * elapsed) / 1000.0
        yRot += (ySpeed * elapsed) / 1000.0
    }
    lastTime = timeNow
}


function tick() {
    requestAnimFrame(tick)
    drawScene()
    animate()
}


function webGLStart() {
    var canvas = document.getElementById("webglCanvas")
    initGL(canvas)
    initShaders()
    initBuffers()
    initTexture()

    gl.clearColor(0.0, 0.0, 0.0, 1.0)
    gl.enable(gl.DEPTH_TEST)

    tick()
}
*/


function drawText(text) {
}


module.exports = {
  makePixmap : makePixmap
, drawText   : drawText
}
