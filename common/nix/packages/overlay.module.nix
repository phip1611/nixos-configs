# NixOS Module that adds `./overlay.nix` to a NixOS configuration.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.phip1611.packages-overlay;
in
{
  options.phip1611.packages-overlay = {
    enable = lib.mkEnableOption "Enable the phip1611 packages overlay";
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [ (import ./overlay.nix) ];
  };
}
