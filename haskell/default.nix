{
  mkDerivation, stdenv
, aeson, array, base, base64-bytestring, binary, bytestring, cereal, containers, data-default, deepseq, GLUT, hashable, kafka-device, kafka-device-glut, lens, linear, logging-effect, milena, mtl, OpenGL, OpenGLRaw, opengl-dlp-stereo, protobuf, split, text, websockets, vector, X11, yaml
, cmdargs
}:

mkDerivation {
  pname = "infovis-parallel";
  version = "1.0.0.0";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  libraryHaskellDepends = [
  ];
  executableHaskellDepends = [
    aeson array base base64-bytestring binary bytestring cereal containers data-default deepseq GLUT hashable kafka-device kafka-device-glut lens linear logging-effect milena mtl OpenGL OpenGLRaw opengl-dlp-stereo protobuf split text websockets vector X11 yaml
    cmdargs
  ];
  homepage = "https://bitbucket.org/bwbush/infovis-parallel";
  description = "Parallel-planes information visualization";
  license = stdenv.lib.licenses.mit;
}
