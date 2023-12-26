# Fonts

{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.user-env;
in
{

  config = lib.mkIf (cfg.enable && cfg.withGui) {
    # https://nixos.wiki/wiki/Fonts
    fonts = {
      packages = with pkgs; [
        # Used/Prefered by many applications, such as "yazi". Comes with
        # powerline symbols.
        nerdfonts
        open-sans
        roboto
        roboto-mono
        source-code-pro
      ];

      # Required by some X11 apps
      fontDir.enable = true;
    };
  };
}
