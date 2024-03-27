{ pkgs }:

import ./nix/build.nix {
  inherit (pkgs) grub2 nix-gitignore stdenv;
}
