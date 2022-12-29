{ lib, callPackage, stdenv, makeWrapper
}:

let
  sac2c-unwrapped = callPackage ./sac2c-unwrapped.nix { };
  sac-stdlib = callPackage ./sac2c-stdlib.nix {
    sac2c-unwrapped = sac2c-unwrapped;
  };

in stdenv.mkDerivation rec {
  version = sac2c-unwrapped.version;
  pname = "sac2c";

  nativeBuildInputs = [
    makeWrapper
  ];

  phases = [
    "installPhase"
  ];

  version_path = builtins.substring 1 (builtins.stringLength version) version;

  installPhase = ''
    mkdir -p $out/bin
    cp -r ${sac2c-unwrapped}/share $out/share
    cp ${sac2c-unwrapped}/bin/* $out/bin/
    substituteInPlace $out/share/sac2c/${version_path}/sac2crc_p \
      --replace "__LIB_STDLIB_PATH__" "${sac-stdlib}/lib/modlibs" \
      --replace "__TREE_STDLIB_PATH__" "${sac-stdlib}/libexec"
    for f in $out/bin/*; do
      wrapProgram $f \
        --set SAC2CRC "$out/share/sac2c/${version_path}/sac2crc_p"
    done
  '';

  meta = with lib; {
    description = "The compiler (sac2c) and StdLib of the Single-Assignment C programming language";
    homepage = "http://www.sac-home.org/";
    license = ./LICENSE.txt;
    maintainers = with maintainers; [ rowanG077 ];
    platforms   = platforms.all;
  };
}
