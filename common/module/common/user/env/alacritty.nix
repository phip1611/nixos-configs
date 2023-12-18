# Sets the configuration for allacritty.

{ config, lib, pkgs, ... }:

let
  username = config.phip1611.username;
  cfg = config.phip1611.common.user.env;
in
{
  config = lib.mkIf (cfg.enable && !cfg.excludeGui) {

    fonts.packages = with pkgs; [
      source-code-pro
    ];

    home-manager.users."${username}" = {
      programs.alacritty = {
        enable = true;
        settings = builtins.fromJSON (builtins.readFile ./alacritty.json);
      };
    };
  };
}
