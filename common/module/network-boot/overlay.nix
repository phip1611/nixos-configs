# This overlay adds additional utility functions to `pkgs`.

_final: prev:

let
  pkgs = prev;
  ipxeNetworkBoot = pkgs.callPackage ./ipxe.nix { };
in
{
  inherit ipxeNetworkBoot;
}
