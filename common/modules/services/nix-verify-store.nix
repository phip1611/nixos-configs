# Warn: This service is relatively heavy and runs for a long time.
#
# I once had a case on host asking-alexandria where the Nix store was
# corrupted due to a kernel panic during a Nix derivation build job, caused
# by a IO uring bug in Linux 6.6. Afterwards, a few items of the store were
# broken. Therefore, it is smart to run this service occasionally. Especially,
# as I am a heavy NixOS user and I love bleeding edge stuff, the likelihood
# that something breaks is not zero.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.phip1611.services.nix-verify-store;
in
{
  options.phip1611.services.nix-verify-store = {
    enable = lib.mkEnableOption "Enable the weekly Nix store verify service";
    intervalMinutes = lib.mkOption {
      type = lib.types.int;
      description = "Interval in minutes for the service to run.";
      # once per hour
      default = 60;
      # once per hour
      example = 60;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd = {
      services.nix-verify-store = {
        enable = true;
        description = "Nix Store Verify & Repair";
        serviceConfig = {
          ExecStart = "${config.nix.package}/bin/nix-store --verify --check-contents --repair";
          Type = "oneshot";
        };
      };
      timers.nix-verify-store = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          RandomizedDelaySec = 1800;
          OnCalendar = "Sun 03:00:00";
          Unit = "nix-verify-store.service";
        };
      };
    };
  };

}
