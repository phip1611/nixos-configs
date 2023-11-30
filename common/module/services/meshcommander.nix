# meshcommander systemd service
# https://github.com/Ylianst/MeshCommander

{ pkgs, lib, config, options, ... }:

let
  cfg = config.phip1611.services.meshcommander;
in
{
  options.phip1611.services.meshcommander = {
    enable = lib.mkEnableOption "Enable the meshcommander web-server for Intel AMT on localhost as systemd service";
    port = lib.mkOption {
      type = lib.types.int;
      description = "Port on localhost for the web-server";
      default = 3000;
    };
  };

  config = lib.mkIf cfg.enable ({
    systemd.services.meshcommander = {
      enable = true;
      restartIfChanged = true;
      description = "Intel AMT Management Server on localhost:3000";
      # Automatic startup when the user logs in.
      wantedBy = [ "default.target" ];
      # The configuration layout for the "serviceConfig" property corresponds
      # to the native file format of systemd services.
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.nodejs}/bin/node ${pkgs.nodePackages.meshcommander}/bin/meshcommander --port ${toString cfg.port}";
        ExecStop = "${pkgs.killall}/bin/killall meshcommander";
        Restart = "always";
      };
    };
  });

}
