{ lib, pkgs, stdenv, fetchgit,
  glibc, libuuid, libxcrypt,
  libxslt, gnum4, python3,
  gcc, binutils, bash,
  autoPatchelfHook,
  cudaPackages, hwloc,
  cmake
}:

stdenv.mkDerivation rec {
  pname = "sac2c-unwrapped";

  version-main = "v1.3.3";
  version-name = "MijasCosta";
  version-commit = "1026";
  version-rev = "g3af2";

  version = "${version-main}-${version-name}-${version-commit}-${version-rev}";

  src = fetchgit {
    url = "https://gitlab.sac-home.org/sac-group/sac2c.git";
    rev = "3af2fd45b0ba04e3150d89ae20c92e9ec143dc2c";
    sha256 = "sha256-2GUW+SqbD9jr+ctFPs1WCj2VvK7XIQZS263SFHO+FHQ=";
  };

  patches = [
    ./sac2crc.patch
  ];

  prePatch = ''
    substituteInPlace cmake/check-repo-version.cmake \
      --replace "\''${GIT_COMMAND} describe --tags --abbrev=4 --dirty" "echo ${version}"
    substituteInPlace cmake/sac2c-version-related.cmake \
      --replace "FIND_PACKAGE (Git)" "SET(GIT_FOUND "1")" \
      --replace "\''${GIT_EXECUTABLE} describe --tags --abbrev=4 --dirty" "echo ${version}" \
      --replace "\''${GIT_EXECUTABLE} diff-index --quiet HEAD" "echo 0"
    substituteInPlace cmake/sac2c/config.cmake \
      --replace "SET (SAC2C_IS_DIRTY 1)" "SET (SAC2C_IS_DIRTY 0)"
    substituteInPlace CMakeLists.txt \
      --replace "-DUSER_HOME=\"\''$ENV{HOME}\"" "-DUSER_HOME=$TMPDIR"
  '';

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=RELEASE"
    "-DCUDA=on"
  ];

  nativeBuildInputs = [
    cmake
    libxslt
    gnum4
    python3
  ];

  buildInputs = [
    libuuid
    libxcrypt
    cudaPackages.cudatoolkit
    hwloc
  ];
}
