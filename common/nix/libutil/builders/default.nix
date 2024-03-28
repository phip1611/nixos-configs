{ pkgs }:

{
  extractVmlinux = pkgs.callPackage ./extract-vmlinux.nix { };
  flattenDrv = import ./flatten-drv.nix { inherit (pkgs) runCommandLocal; };
  unflattenDrv = import ./unflatten-drv.nix { inherit (pkgs) runCommandLocal; };
}
