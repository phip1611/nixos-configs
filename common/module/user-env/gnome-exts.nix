# GUI/Desktop Apps

{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.user.pkgs.gnome-exts;
  username = config.phip1611.username;
  gnomeEnabled = config.services.xserver.displayManager.gdm.enable &&
    config.services.xserver.desktopManager.gnome.enable;
in
{
  options = {
    phip1611.common.user.pkgs.gnome-exts.enable = lib.mkEnableOption "Enable GNOME extensions";
  };

  config = lib.mkIf (cfg.enable && gnomeEnabled) {
    users.users."${username}".packages = with pkgs; [
      gnome.dconf-editor
      gnome.gnome-tweaks
      gnomeExtensions.clock-override
      # This is only a subset of extensions but dash-to-dock
      # is the most important one. However, without further
      # configuration, it doesn't look what I want it to look like.
      gnomeExtensions.dash-to-dock
      gnomeExtensions.places-status-indicator
      gnomeExtensions.emoji-selector
    ];
  };
}
