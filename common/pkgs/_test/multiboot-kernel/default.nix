{ pkgs ? import <nixpkgs> { }
}:

import ./build.nix {
  inherit (pkgs) grub2 lib stdenv;
}
