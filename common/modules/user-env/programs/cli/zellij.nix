{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.user-env;
in
{
  config = lib.mkIf cfg.enable {
    home-manager.users."${cfg.username}" = {
      programs.zellij.enable = true;
      programs.zellij.settings = {
        theme = "catppuccin-mocha";
        default_layout = "compact";
        copy_on_select = false;
        ui.pane_frames.hide_session_name = true;
      };
    };
  };
}
