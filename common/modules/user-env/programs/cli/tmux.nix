{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.user-env;
in
{
  config = lib.mkIf cfg.enable {
    home-manager.users."${cfg.username}" = {
      programs.tmux.enable = true;
      programs.tmux.extraConfig = builtins.readFile ./tmux.cfg;
    };
  };
}
