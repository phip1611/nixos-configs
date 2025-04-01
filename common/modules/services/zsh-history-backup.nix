# zsh-history-backup systemd user service for every user on the system.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.phip1611.services.zsh-history-backup;
  # Get package from overlay.
  pkg = pkgs.phip1611.packages.zsh-history-backup;
in
{
  options.phip1611.services.zsh-history-backup = {
    enable = lib.mkEnableOption "Enable a regularly scheduled backup of your `zsh` history`";
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
    systemd.user.services.zsh-history-backup = {
      enable = true;
      description = "zsh-history-backup (per-user) service";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getExe pkg}";
      };
    };
    systemd.user.timers.zsh-history-backup-update = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "0m";
        OnUnitActiveSec = "${toString cfg.intervalMinutes}m";
        Unit = "zsh-history-backup.service";
      };
    };
  };

}
