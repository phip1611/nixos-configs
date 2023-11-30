{ pkgs, lib, config, options, ... }:

let
  cfg = config.phip1611.common.user;
in
{
  imports = [
    ./env
    ./pkgs
  ];

  options = {
    phip1611.common.user.enable = lib.mkEnableOption "Enable all user sub-modules at once";
  };

  config = lib.mkIf cfg.enable {
    phip1611.common.user.env.enable = lib.mkDefault true;
    phip1611.common.user.pkgs.enable = lib.mkDefault true;
  };
}
