# NixOS Module that adds `./overlay.nix` to a NixOS configuration.

{
  lib,
  config,
  options,
  ...
}:

let
  cfg = config.phip1611.bootitems-overlay;
in
{
  options.phip1611.bootitems-overlay = {
    enable = lib.mkEnableOption "Enable the phip1611 bootitems overlay";
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [ (import ./overlay.nix) ];
  };
}
