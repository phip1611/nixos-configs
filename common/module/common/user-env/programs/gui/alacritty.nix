# Sets the configuration for allacritty.

{ config, lib, pkgs, nixpkgs-unstable, ... }:

let
  cfg = config.phip1611.common.user-env;
  username = config.phip1611.username;
  pkgsUnstable = import nixpkgs-unstable {
    system = pkgs.system;
    config = {
      allowUnfree = true;
    };
  };
in
{
  config = lib.mkIf (cfg.enable && cfg.withGui) {

    fonts.packages = with pkgs; [
      source-code-pro
    ];

    home-manager.users."${username}" = {
      programs.alacritty = {
        enable = true;
        package = pkgsUnstable.alacritty;
        settings = builtins.fromJSON (builtins.readFile ./alacritty.json);
      };
    };
  };
}
