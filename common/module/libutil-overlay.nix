# NixOS Module that adds `./overlay.nix` to a NixOS configuration.

{ lib, config, options, ... }:

let
  cfg = config.phip1611.libutil-overlay;
in
{
  options.phip1611.libutil-overlay = {
    enable = lib.mkEnableOption "Enable the libutil overlay";
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [ (import ../libutil/overlay.nix) ];
  };
}
