# Enables a cool boot screen.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.phip1611.common.system;
  plymouthThemePackage = pkgs.callPackage ./plymouth-themes/phips-unlock { };
in
{
  config = lib.mkIf (cfg.enable && cfg.withBootscreen) {
    boot.plymouth = {
      enable = true;
      font = "${pkgs.open-sans}/share/fonts/truetype/OpenSans-Regular.ttf";
      # The logo is not part of the theme and externally provided.
      logo = ./plymouth-themes/phips-unlock/background.png;
      theme = "phips-unlock";
      themePackages = [ plymouthThemePackage ];
    };

    boot.consoleLogLevel = 0;
    boot.kernelParams = [
      "quiet"

      # No "[ OK ] Started ..." / systemd logs
      "systemd.show_status=false"

      # no udev spam
      "udev.log_level=3"
      "rd.udev.log_level=3"

      # No blinking cursor between Plymouth and Display Manager
      "vt.global_cursor_default=0"
    ];
  };
}
