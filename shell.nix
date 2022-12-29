{ pkgs ? import <nixpkgs> {} }:
let sac2c = pkgs.callPackage ./default.nix { };
in pkgs.mkShell {
    nativeBuildInputs = [ sac2c ];
}
