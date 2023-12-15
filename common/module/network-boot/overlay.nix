# This overlay adds additional utility functions to `pkgs`.

final: prev:

let
  pkgs = prev;
  ipxeNetworkBoot = pkgs.callPackage ./ipxe.nix { };
in
{
  inherit ipxeNetworkBoot;
}
