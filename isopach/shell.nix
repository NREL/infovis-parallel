{
  gitLocal ? true
, immersiveIsopach ? false
, stereoIsopach ? false
}:

with import <nixpkgs> {};

let
  libisopach_0_6 = import ./libisopach_0_6.nix {
    inherit gitLocal immersiveIsopach stereoIsopach stdenv fetchgit cmake doxygen glm mesa openmpi qt56 vrpn xorg;
  };
  plottyr = import ./plottyr.nix {
    inherit gitLocal stdenv fetchgit cmake libisopach_0_3;
  };
  librecords = import ./librecords.nix {
    inherit gitLocal stdenv fetchgit cmake ;
  };

in
  stdenv.mkDerivation rec {
    name = "nrel-vis-tools";
    buildInputs =  [
      libisopach_0_6
    ];
  }
