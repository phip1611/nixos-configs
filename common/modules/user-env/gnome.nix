{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.user-env;
  gnomeEnabled = config.services.xserver.displayManager.gdm.enable &&
    config.services.xserver.desktopManager.gnome.enable;
in
{
  config = lib.mkIf (cfg.enable && gnomeEnabled) {
    users.users."${cfg.username}".packages = with pkgs; [
      gnome.gnome-tweaks
      # This is only a subset of extensions but dash-to-dock
      # is the most important one. However, without further
      # manual out-of-Nix configuration, it doesn't look what I want it to look
      # like.
      gnomeExtensions.dash-to-dock
    ];

    # GNOME 46: triple-buffering
    # See https://nixos.wiki/wiki/GNOME
    nixpkgs.overlays =
      let
        branch = "triple-buffering-v4-46";
        sha256 = "sha256:1fqss0837k3sc7hdixcgy6w1j73jdc57cglqxdc644a97v5khnr3";
      in
      [
        (_final: prev: {
          gnome = prev.gnome.overrideScope (_gnomeFinal: gnomePrev: {
            mutter = gnomePrev.mutter.overrideAttrs (_old: {
              # See https://gitlab.gnome.org/GNOME/mutter/-/merge_requests/1441
              # to select a proper branch.
              src = builtins.fetchTarball {
                url = "https://gitlab.gnome.org/vanvugt/mutter/-/archive/${branch}/mutter-${branch}.tar.gz";
                inherit sha256;
              };
            });
          });
        })
      ];
  };
}
