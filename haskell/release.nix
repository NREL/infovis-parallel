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
              infovis-parallel  = haskellPackagesNew.callPackage                       ./default.nix { };
              kafka-device      = haskellPackagesNew.callPackage      ../../kafka-device/default.nix { };
              kafka-device-glut = haskellPackagesNew.callPackage ../../kafka-device-glut/default.nix { };
            };
          };
        };
      };
    };
  };
  pkgs = nixpkgs { inherit config; };
in
  {
    infovis-parallel = pkgs.haskell.packages."${compiler}".infovis-parallel;
  }
