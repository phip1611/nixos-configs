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
      totem
      yelp
    ];

    # GNOME 46: triple-buffering
    # See https://nixos.wiki/wiki/GNOME
    #
    # TODO Is this upstremed to GNOME 47/nixpkgs yet?
    nixpkgs.overlays =
      let
        # Picked a recent commit from the "triple-buffering-v4-46" branch:
        # https://gitlab.gnome.org/vanvugt/mutter/-/commits/triple-buffering-v4-46?ref_type=heads
        rev = "94f500589efe6b04aa478b3df8322eb81307d89f";
        sha256 = "sha256:14ln7rgizqg89gdfv6pxjsxjwhfxbd28zwnyxbs1ag23zq3y6hvy";
        url = "https://gitlab.gnome.org/vanvugt/mutter/-/archive/${rev}/mutter-${rev}.tar.gz";
      in
      [
        (_final: prev: {
          gnome = prev.gnome.overrideScope (
            _gnomeFinal: gnomePrev: {
              mutter = gnomePrev.mutter.overrideAttrs (_old: {
                # See https://gitlab.gnome.org/GNOME/mutter/-/merge_requests/1441
                # to select a proper branch.
                src = builtins.fetchTarball {
                  inherit url sha256;
                };
              });
            }
          );
        })
      ];
  };
}
