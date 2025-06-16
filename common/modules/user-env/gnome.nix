{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.phip1611.common.user-env;
  gnomeEnabled =
    config.services.xserver.displayManager.gdm.enable
    && config.services.xserver.desktopManager.gnome.enable;
in
{
  config = lib.mkIf (cfg.enable && gnomeEnabled) {
    users.users."${cfg.username}".packages = with pkgs; [
      gnome-tweaks
      # This is only a subset of extensions but dash-to-dock
      # is the most important one. However, without further
      # manual out-of-Nix configuration, it doesn't look what I want it to look
      # like.
      gnomeExtensions.dash-to-dock
    ];

    environment.gnome.excludePackages = with pkgs; [
      baobab
      epiphany
      geary
      gnome-calculator
      gnome-characters
      gnome-connections
      gnome-console
      gnome-contacts
      gnome-logs
      gnome-maps
      gnome-software
      gnome-system-monitor
      gnome-text-editor
      gnome-tour
      gnome-user-docs
      orca
      simple-scan
      snapshot
      yelp
    ];
  };
}
