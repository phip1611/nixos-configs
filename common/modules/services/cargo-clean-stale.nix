# Daily systemd user service that frees disk space in the target directories
# of Rust projects, for every normal user. It cleans projects that were not
# built in the last 7 days and removes unused artifacts in the others. See the
# cargo-clean-stale package for details.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.phip1611.services.cargo-clean-stale;
  # Get package from overlay.
  pkg = pkgs.phip1611.packages.cargo-clean-stale;
in
{
  options.phip1611.services.cargo-clean-stale = {
    enable = lib.mkEnableOption "Free disk space in the target directories of Rust projects daily";
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.cargo-clean-stale = {
      description = "Free disk space in target directories of Rust projects";
      unitConfig = {
        # Skip root and system users.
        ConditionUser = "!@system";
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getExe pkg}";
        # Walking large target directories shouldn't slow down my work.
        Nice = 19;
        IOSchedulingClass = "idle";
      };
    };
    systemd.user.timers.cargo-clean-stale = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        # Catch up on a missed run at the next login.
        Persistent = true;
        Unit = "cargo-clean-stale.service";
      };
    };
  };
}
