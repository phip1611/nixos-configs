# Activates the Nix binary cache with the artifacts for this project.

{ config, pkgs, lib, ... }:

let
  cfg = config.phip1611.common.system;
in
{
  options.phip1611.common.system.withSelfBinaryCache = lib.mkEnableOption "Enables the Nix binary cache with the artifacts of this project/repository (\"self\")";

  config = lib.mkIf cfg.enable {
    nix = {
      settings = {
        # Additive, so the default substituters are not replaced.
        substituters = [ "https://nix-binary-cache.phip1611.dev" ];
        trusted-public-keys = [ "nix-binary-cache.phip1611.dev:LOpIoU+QQRaKhUTbIU6k5+5BU3Ff0Y4rViXfgRarEvk=" ];
      };
    };
  };
}
