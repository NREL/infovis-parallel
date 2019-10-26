
const Buffers = require("./buffers")
const Program = require("./program")

function main(gl) {

    const shapeProgram = Program.prepareShapeProgram(gl);
    Program.selectShapeProgram(gl, shapeProgram)

    const vertexPosBuffer = Buffers.buildBuffer(gl, [[-0.3, -0.5], [0.3, -0.5], [0.0, 0.5]], shapeProgram.meshDescription)
    Program.bindAttributes(gl, false, shapeProgram.meshLocation, shapeProgram.meshDescription, vertexPosBuffer)

    const vertexColorBuffer = Buffers.buildBuffer(gl, [[1.0, 0.5, 0.0], [0.0, 0.5, 1.0]], shapeProgram.colorsDescription)
    Program.bindAttributes(gl, true, shapeProgram.colorsLocation, shapeProgram.colorsDescription, vertexColorBuffer)

    gl.clearColor(0.0, 0.0, 0.0, 1.0);
    gl.clear(gl.COLOR_BUFFER_BIT);
    gl.drawArraysInstanced(gl.TRIANGLES, 0, 3, 2);
}

module.exports = {
  main : main
}
