# Sets up auto-upgrades of the NixOS system via a scheduled
# `$ nixos-rebuild boot --flake` and a following reboot.
#
# This should only done on systems that:
# - follow a stable NixOS release
# - are fully build and tested in CI in this repository
# - are server(-like) environments that I rarely touch

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.phip1611.common.system;
in
{
  config = lib.mkIf (cfg.enable && cfg.withAutoUpgrade) {
    system.autoUpgrade = {
      enable = true;
      flake = "github:phip1611/nixos-configs";
      flags = [
        "--no-write-lock-file"
        "-L" # print build logs
      ];
      operation = "boot";
      allowReboot = true;
      dates = "02:00";
      rebootWindow = {
        lower = "02:00";
        upper = "05:00";
      };
      randomizedDelaySec = "45min";
    };
  };
}
