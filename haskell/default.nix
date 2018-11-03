{
  mkDerivation, stdenv
, aeson, base, base64-bytestring, bytestring, protobuf, text, websockets, yaml
, cmdargs
}:

mkDerivation {
  pname = "infovis-parallel";
  version = "1.0.0.0";
  src = ./.;
  isLibrary = true;
  isExecutable = true;
  libraryHaskellDepends = [
    aeson base base64-bytestring bytestring protobuf text websockets yaml
  ];
  executableHaskellDepends = [
    aeson base base64-bytestring bytestring cmdargs protobuf text websockets yaml
  ];
  homepage = "https://bitbucket.org/bwbush/infovis-parallel";
  description = "Parallel-planes information visualization";
  license = stdenv.lib.licenses.mit;
}
