{ config, lib, pkgs, nixpkgs-unstable, ... }:

let
  cfg = config.phip1611.common.user-env;
  pkgsUnstable = import nixpkgs-unstable {
    system = pkgs.system;
    config = {
      allowUnfree = true;
    };
  };
  alacritty = pkgsUnstable.alacritty;
in
{
  config = lib.mkIf (cfg.enable && cfg.withGui) {

    fonts.packages = with pkgs; [
      source-code-pro
    ];

    home-manager.users."${cfg.username}" = {
      programs.alacritty = {
        enable = true;
        package = alacritty;
        settings = builtins.fromTOML (builtins.readFile ./alacritty.toml);
      };
    };
  };
}
