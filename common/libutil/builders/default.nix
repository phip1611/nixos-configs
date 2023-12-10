{ runCommandLocal }:

{
  flattenDrv = import ./flatten-drv.nix { inherit runCommandLocal; };
  unflattenDrv = import ./unflatten-drv.nix { inherit runCommandLocal; };
}
