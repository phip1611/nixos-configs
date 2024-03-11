# Initializes `pkgs` for quick prototyping of the tests with all relevant
# overlays applied. Not used when exported via the flake.

import <nixpkgs> {
  overlays = [
    (import ./bootitems/overlay.nix)
    (import ./libutil/overlay.nix)
    (import ./packages/overlay.nix)
  ];
}
