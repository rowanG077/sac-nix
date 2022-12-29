{ lib, fetchgit, stdenv, sac2c-unwrapped
, cmake, git, bison, flex
, cudaPackages, patchelf
}:

stdenv.mkDerivation rec {
  pname = "sac-stdlib";
  version = "1.3-145-gc52d";

  src = fetchgit {
    url = "https://github.com/SacBase/Stdlib.git";
    rev = "c52d4e4f8445cb66bc8c11d1e372770091078a92";
    sha256 = "sha256-ClJm3anqeX8or//EDaKk1D5KRjPppDrMwUGzdMm1HP4=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cmake
    git
    bison
    flex
    patchelf
  ];

  buildInputs = [
    sac2c-unwrapped
    cudaPackages.cudatoolkit
  ];

  targets = [ "seq" "mt_pth" "cuda" ];

  prePatch = ''
    substituteInPlace cmake-common/generate-version-vars.cmake \
      --replace "\''${GIT_EXECUTABLE} describe --tags --abbrev=4 --dirty" "echo ${version}"
    substituteInPlace cmake-common/misc-macros.cmake \
      --replace "-DUSER_HOME=\"\''$ENV{HOME}\"" "-DUSER_HOME=$TMPDIR"
    substituteInPlace src/CMakeLists.txt \
      --replace "MESSAGE (DEBUG" " MESSAGE (STATUS" \
      --replace \
        "STRING (REPLACE \"/usr/local/\" \"\" _install_mod_dir \''${INSTALL_MOD_DIR})" \
        "set(_install_mod_dir \"${placeholder "out"}/lib/modlibs\")" \
      --replace \
        "STRING (REPLACE \"/usr/local/\" \"\" _install_tree_dir \''${INSTALL_TREE_DIR})" \
        "set(_install_tree_dir \"${placeholder "out"}/libexec\")"
  '';

  preInstall = ''
    mkdir -p $out/share
    cp -r $TMPDIR/.sac2crc $out/share/.sac2crc
  '';

  # For some reason the libs bake in the ephemeral build path instead of the
  # install path. Remove the ephemeral path and replace it with the correct
  # install path
  targets2 = map (x: builtins.replaceStrings ["_"] ["-"] x) targets;
  preFixup = ''
    for p in ${builtins.concatStringsSep " " targets2}; do
      for f in $out/lib/modlibs/host/$p/*.so; do
        RPATH=$(patchelf --print-rpath $f)
        IFS=':' read -a RPATHS <<< $RPATH
        RPATHS=("''${RPATHS[@]:1}")
        RPATHS=("$out/lib/modlibs/host/$p" "''${RPATHS[@]}")
        RPATH=$(IFS=:; printf '%s' "''${RPATHS[*]}")
        patchelf --set-rpath $RPATH $f
      done
    done
  '';

  cmakeFlags = [
    "-DTARGETS=${builtins.concatStringsSep ";" targets}"
    "-DIS_RELEASE=TRUE"
  ];

  meta = with lib; {
    description = "The standard library for the Single-Assignment C programming language";
    homepage = "http://www.sac-home.org/";
    maintainers = with maintainers; [ rowanG077 ];
    platforms   = platforms.all;
  };
}
