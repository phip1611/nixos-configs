# Sets up auto-upgrades of the NixOS system via a scheduled
# `$ nixos-rebuild boot --flake` and a following reboot.
# This should only done on systems that:
# - follow a stable NixOS release
# - are fully build and tested in CI in this repository
# - are server(-like) environments that I rarely touch

{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.system.auto-upgrade;
in
{
  options = {
    phip1611.common.system.auto-upgrade = {
      enable = lib.mkEnableOption "Enable Auto-Upgrade of the flake";
      # The flake to update from. It's okay to not specify the attribute name,
      # as `nixos-rebuild --flake` uses the hostname by default for that.
      flake = lib.mkOption {
        type = lib.types.str;
        description = "The flake reference to update from.";
        default = "github:phip1611/nixos-configs";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    system.autoUpgrade = {
      enable = true;
      flake = cfg.flake;
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
