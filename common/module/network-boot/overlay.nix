# This overlay adds additional utility functions to `pkgs`.

_self: super:

let
  pkgs = super.pkgs;
  ipxeNetworkBoot = pkgs.callPackage ./ipxe.nix { };
in
{
  inherit ipxeNetworkBoot;
}
