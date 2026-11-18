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

    # CUPS creates temporary queues for printers visible on the current
    # network. The persistent queues of cups-browsed stay selectable when the
    # printer is out of reach and retry jobs until it is reachable again.
    services.printing.browsed.enable = false;

    # Avahi handles mDNS. A second mDNS stack makes mDNS unreliable.
    services.resolved.settings.Resolve.MulticastDNS = false;
  };
}
