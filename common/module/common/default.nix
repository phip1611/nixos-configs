# Common configurations for my NixOS systems for system-wide and user-specific
# settings.

{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common;
in
{
  imports = [
    ./system
    ./user-env
  ];

  options.phip1611.common = {
    enable = lib.mkEnableOption "Enable all common sub-modules at once";
  };

  config = lib.mkIf cfg.enable {
    phip1611.common.system.enable = true;
    phip1611.common.user-env.enable = true;
  };

}
