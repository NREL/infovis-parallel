{
  nixpkgs  ? null
, compiler ? "ghc822"
}:

let

  nixpkgs1 =
    if nixpkgs == null
      then let
             bootstrap = import <nixpkgs> { };
             location = builtins.fromJSON (builtins.readFile ../nixpkgs.json);
             src = bootstrap.fetchFromGitHub {
               owner = "NixOS";
               repo  = "nixpkgs";
               inherit (location) rev sha256;
             };
           in
            import src
      else nixpkgs;

  pkgs = nixpkgs1 { };

  release = (import ../release.nix) {nixpkgs = nixpkgs1; compiler = compiler;};

in

  pkgs.stdenv.mkDerivation {
    name = "env-ivp";
    buildInputs = [
      pkgs.gnumake
      pkgs.jre
      pkgs.zookeeper
      pkgs.apacheKafka011
      pkgs.kafkacat
#     release.infovis-parallel
      release.kafka-device-joystick
      release.kafka-device-spacenav
#     release.kafka-device-vrpn
    ];
  }
