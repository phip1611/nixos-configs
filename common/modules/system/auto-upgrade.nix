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
    # The host auto-updates itself from THIS flake on GitHub. It switches
    # directly to any new configuration. Further, it reboots if the new
    # generation uses a different kernel, kernel modules, or initrd than the
    # booted system.
    system.autoUpgrade = {
      enable = true;
      # Local time
      dates = "02:00";
      # hostname/configuration-name is implicit
      flake = "github:phip1611/nixos-configs";
      operation = "switch";
      flags = [
        "--no-write-lock-file"
        "-L" # print build logs
      ];
      allowReboot = true;
      rebootWindow = {
        lower = "03:00";
        upper = "03:00";
      };
      # The global `nix.gc` settings apply. No additional GC trigger needed.
      runGarbageCollection = false;
    };

    # Nobody watches the unattended reboots. If a new generation doesn't
    # reach `boot-complete.target` within the given tries, e.g., due to a
    # broken kernel or initrd, systemd-boot falls back to the previous one.
    # Each try needs a reboot, e.g., a reset by the hoster's panel.
    boot.loader.systemd-boot.bootCounting.enable = true;
  };
}
