{ config, lib, pkgs, ... }:

let
  username = config.phip1611.username;
  cfg = config.phip1611.common.user-env;
in
{
  config = lib.mkIf cfg.enable {
    home-manager.users."${username}" = {
      programs.micro.enable = true;
      programs.micro.settings = {
        colorcolumn = 80;
        rmtrailingws = true;
        savecursor = true;
        tabsize = 2;
      };
    };
  };
}
