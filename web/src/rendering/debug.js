
const Buffers = require("./buffers")
const Program = require("./program")

const vs = `#version 300 es
layout(location = 0) in vec2 pos;
layout(location = 1) in vec4 color;
flat out vec4 v_color;
void main()
{
    v_color = color;
    gl_Position = vec4(pos + vec2(float(gl_InstanceID) - 0.5, 0.0), 0.0, 1.0);
}`

const fs = `#version 300 es
precision highp float;
flat in vec4 v_color;
out vec4 color;
void main()
{
    color = v_color;
}`

function main(gl) {

    var shapeProgram = Program.prepareShapeProgram(gl, vs, fs);
    Program.selectShapeProgram(gl, shapeProgram)

    const vertexPosDescription = {components: 2, isFloat: true}
    const vertexPosBuffer = Buffers.buildBuffer(gl, [[-0.3, -0.5], [0.3, -0.5], [0.0, 0.5]], vertexPosDescription)
    var vertexPosLocation = 0;
    Program.bindAttributes(gl, false, vertexPosLocation, vertexPosDescription, vertexPosBuffer)

    const vertexColDescription = {components: 3, isFloat: true}
    const vertexColorBuffer = Buffers.buildBuffer(gl, [[1.0, 0.5, 0.0], [0.0, 0.5, 1.0]], vertexColDescription)
    var vertexColorLocation = 1;
    Program.bindAttributes(gl, true, vertexColorLocation, vertexColDescription, vertexColorBuffer)

    gl.clearColor(0.0, 0.0, 0.0, 1.0);
    gl.clear(gl.COLOR_BUFFER_BIT);
    gl.drawArraysInstanced(gl.TRIANGLES, 0, 3, 2);
}

module.exports = {
  main : main
}
