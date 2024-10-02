{ config, lib, pkgs, ... }@inputs:

let
  cfg = config.phip1611.common.user-env;
  pkgsUnstable = import inputs.nixpkgs-unstable {
    system = pkgs.system;
  };
in
{
  config = lib.mkIf (cfg.enable && cfg.withGui) {

    fonts.packages = with pkgs; [
      source-code-pro
    ];

    home-manager.users."${cfg.username}" = {
      programs.alacritty = {
        enable = true;
        package = pkgsUnstable.alacritty;
        settings = builtins.fromTOML (builtins.readFile ./alacritty.toml);
      };
    };
  };
}
