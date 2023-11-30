# A tiny nix shell for testing that adds the customPkgs of libutil to the PATH.

let
  pkgs = import <nixpkgs> { };
  libutil = import ./default.nix { inherit pkgs; };
in
pkgs.mkShell rec {
  nativeBuildInputs = builtins.attrValues libutil.customPkgs;
}
