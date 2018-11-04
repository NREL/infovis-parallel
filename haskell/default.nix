{
  mkDerivation, stdenv
, aeson, base, base64-bytestring, bytestring, containers, data-default, lens, linear, logging-effect, mtl, protobuf, split, text, websockets, yaml
, cmdargs
}:

mkDerivation {
  pname = "infovis-parallel";
  version = "1.0.0.0";
  src = ./.;
  isLibrary = true;
  isExecutable = true;
  libraryHaskellDepends = [
    aeson base base64-bytestring bytestring containers data-default lens linear logging-effect mtl protobuf split text websockets yaml
  ];
  executableHaskellDepends = [
    cmdargs
  ];
  homepage = "https://bitbucket.org/bwbush/infovis-parallel";
  description = "Parallel-planes information visualization";
  license = stdenv.lib.licenses.mit;
}
