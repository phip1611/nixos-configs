{ pkgs ? import <nixpkgs> { }
, callPackage ? pkgs.callPackage
}:

import ./build.nix {
  inherit (pkgs) grub2 lib stdenv;
}
