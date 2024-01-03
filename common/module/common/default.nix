# Common Configurations for my NixOS systems.

{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common;
in
{
  imports = [
    ./system
    ./user
  ];

  options.phip1611.common = {
    enable = lib.mkEnableOption "Enable all common sub-modules at once";
  };

  config = lib.mkIf cfg.enable {
    phip1611.common.user.enable = true;
    phip1611.common.system.enable = true;
  };

}
