{
  nixpkgs  ? import <nixos-unstable>
, compiler ? "ghc822"
}:

let
  config = {
    packageOverrides = pkgs: rec {
      haskell = pkgs.haskell // {
        packages = pkgs.haskell.packages // {
          "${compiler}" = pkgs.haskell.packages."${compiler}".override {
            overrides = haskellPackagesNew: haskellPackagesOld: rec {
              infovis-parallel      = haskellPackagesNew.callPackage                           ./default.nix { };
              kafka-device          = haskellPackagesNew.callPackage          ../../kafka-device/default.nix { };
              kafka-device-glut     = haskellPackagesNew.callPackage     ../../kafka-device-glut/default.nix { };
              kafka-device-joystick = haskellPackagesNew.callPackage ../../kafka-device-joystick/default.nix { };
              kafka-device-spacenav = haskellPackagesNew.callPackage ../../kafka-device-spacenav/default.nix { };
            };
          };
        };
      };
    };
  };
  pkgs = nixpkgs { inherit config; };
in
  {
    infovis-parallel      = pkgs.haskell.packages."${compiler}".infovis-parallel     ;
    kafka-device          = pkgs.haskell.packages."${compiler}".kafka-device         ;
    kafka-device-joystick = pkgs.haskell.packages."${compiler}".kafka-device-joystick;
    kafka-device-spacenav = pkgs.haskell.packages."${compiler}".kafka-device-spacenav;
  }
