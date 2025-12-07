# ddns-update systemd service

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.phip1611.services.ddns-update;
  # Get package from overlay.
  pkg = pkgs.phip1611.packages.ddns-update;
in
{
  options.phip1611.services.ddns-update = {
    enable = lib.mkEnableOption "Enable the DDNS update timer using the ddns-update utility";
    configPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      # Should not be in Nix store due to the embedded secret!
      # Ideally, this file is only readable as root for maximum security.
      description = "Absolute path to the config file";
      default = null;
      example = "/home/user/ddns-update.json";
    };
    intervalMinutes = lib.mkOption {
      type = lib.types.int;
      description = "Interval in minutes for the service.";
      default = 5;
      example = 5;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.ddns-update = {
      enable = true;
      description = "ddns-update service";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getExe pkg} --config ${cfg.configPath}";
      };
    };
    systemd.timers.ddns-update = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "0m";
        OnUnitActiveSec = "${toString cfg.intervalMinutes}m";
        Unit = "ddns-update.service";
      };
    };
  };

}
