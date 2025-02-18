# Adds additional sane printing configurations when printing is enabled.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.phip1611.common.system;
in
{
  config = lib.mkIf (cfg.enable && config.services.printing.enable) {
    services.printing.drivers = with pkgs; [
      # For older Epson printers
      epson-escpr
      # For modern Epson printers
      epson-escpr2
      # Covers various printers
      gutenprint
      # Also covers binary-only drivers
      gutenprintBin
      hplip
    ];

    services.avahi.enable = true;
    services.avahi.nssmdns4 = true;
    services.avahi.nssmdns6 = true;
    services.avahi.openFirewall = true;
  };
}
