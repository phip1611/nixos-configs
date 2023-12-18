# Fonts

{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.user.pkgs.fonts;
in
{
  options = {
    phip1611.common.user.pkgs.fonts.enable = lib.mkEnableOption "Enable my typical fonts (source code pro, ,...)";
  };

  config = lib.mkIf cfg.enable {
    # https://nixos.wiki/wiki/Fonts
    fonts = {
      packages = with pkgs; [
        # Used/Prefered by many applications, such as "yazi".
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
