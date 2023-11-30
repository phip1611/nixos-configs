# This overlay adds libutil to nixpkgs.
# The overlay is strictly additive and all functionality is behind the
# `phip1611-util` attribute.

final: prev:

{
  phip1611-util = import ./default.nix {
    pkgs = final;
  };
}
