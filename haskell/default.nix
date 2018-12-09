{
  mkDerivation, stdenv
, aeson, array, base, base64-bytestring, binary, bytestring, cereal, containers, data-default, deepseq, GLUT, hashable, lens, linear, logging-effect, mtl, OpenGL, OpenGLRaw, opengl-dlp-stereo, protobuf, split, text, websockets, vector, yaml
, cmdargs
}:

mkDerivation {
  pname = "infovis-parallel";
  version = "1.0.0.0";
  src = ./.;
  isLibrary = true;
  isExecutable = true;
  libraryHaskellDepends = [
    aeson array base base64-bytestring binary bytestring cereal containers data-default deepseq GLUT hashable lens linear logging-effect mtl OpenGL OpenGLRaw opengl-dlp-stereo protobuf split text websockets vector yaml
  ];
  executableHaskellDepends = [
    cmdargs
  ];
  homepage = "https://bitbucket.org/bwbush/infovis-parallel";
  description = "Parallel-planes information visualization";
  license = stdenv.lib.licenses.mit;
}
