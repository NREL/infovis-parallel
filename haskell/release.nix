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
              #mkDerivation = args: haskellPackagesOld.mkDerivation ( args // {
              ## enableLibraryProfiling = true;
              ## doCheck = false;
              ## doHaddock = false;
              #});
              infovis-parallel = haskellPackagesNew.callPackage ./default.nix       {                };
              vulkan-api       = haskellPackagesNew.callPackage ./vulkan-api.nix    { vulkan = null; };
              GLFW-b           = haskellPackagesNew.callPackage ./GLFW-b.nix        {                };
              bindings-GLFW    = haskellPackagesNew.callPackage ./bindings-GLFW.nix {
                                                                                        inherit (pkgs)      libGL;
                                                                                        inherit (pkgs.xorg) libX11; 
                                                                                        inherit (pkgs.xorg) libXcursor;
                                                                                        inherit (pkgs.xorg) libXext; 
                                                                                        inherit (pkgs.xorg) libXfixes;
                                                                                        inherit (pkgs.xorg) libXi; 
                                                                                        inherit (pkgs.xorg) libXinerama;
                                                                                        inherit (pkgs.xorg) libXrandr; 
                                                                                        inherit (pkgs.xorg) libXxf86vm;
                                                                                      };
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
