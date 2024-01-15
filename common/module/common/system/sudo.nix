{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.system.sudo;
in
{
  options = {
    phip1611.common.system.sudo = {
      enable = lib.mkEnableOption "Enable extra sudo config: set timeout to 30min";
    };
  };

  config = lib.mkIf cfg.enable {
    # Set sudo password timeout to 30 min instead of 5 min.
    security.sudo.extraConfig = ''
      Defaults        timestamp_timeout=30
    '';
  };
}
