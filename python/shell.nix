with import <nixpkgs> {};

let

  env = (
    python37.withPackages (ps: with ps; [
      matplotlib
      numpy
      pandas
      protobuf
      websockets
    ])
  ).env;

in
  lib.overrideDerivation env (old: {
    shellHook = ''
    '';
  })
