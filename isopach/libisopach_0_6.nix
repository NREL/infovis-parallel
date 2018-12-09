{
  gitLocal ? false, immersiveIsopach ? false, stereoIsopach ? false,
  stdenv, fetchgit, cmake, doxygen,
  glm, mesa, openmpi, qt56, vrpn, xorg
}:

stdenv.mkDerivation rec {
  name = "LibIsopach-${version}";
  version = "0.6";
  src = fetchgit {
    url             = if gitLocal
                        then "git://127.0.0.1/"
                        else "https://github.nrel.gov/nbrunhar/LibIsopach.git";
    rev             = "e87cf86554138414000ba42e913e80b8f299f3c8";
    sha256          = "02z5lngxbfp4k3bc8nmkfp8xsa49ac6x8hbaj7a5h26792qpbxb8";
    fetchSubmodules = true;
  };
  preConfigure = ''
    sed -i -e '94d ; 177d ; 178d' CMakeLists.txt
    sed -i -e '14a#include <functional>' src/scenegraph/scenegraphinternal.h
    sed -i -e  '6a#include <functional>' src/isoclient/utility/concurrent.h
  '';
  cmakeFlags = [
    ("-DIMMERSIVE=" + (if immersiveIsopach then "ON" else "OFF"))
    ("-DSTEREO="    + (if stereoIsopach    then "ON" else "OFF"))
  ];
  enableParallelBuilding = true;
  nativeBuildInputs = [
    cmake doxygen
  ];
  propagatedBuildInputs = [
    glm mesa openmpi qt56.qtimageformats qt56.full vrpn xorg.libX11
  ];
  libPath = [ glm mesa openmpi qt56.qtimageformats qt56.full vrpn xorg.libX11 ];
  meta = {
    description = "Isopach2 is a graphics engine targetting multiscreen immersive environments.";
    homepage = "https://github.nrel.gov/nbrunhar/LibIsopach";
    platforms = stdenv.lib.platforms.linux;
  };
}
