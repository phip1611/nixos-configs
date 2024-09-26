{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.system;
in
{
  config = lib.mkIf cfg.enable {
    # Improve network analysis.
    networking.firewall.allowPing = true;
    networking.firewall.rejectPackets = true;

    networking.firewall.allowedTCPPorts = [
      5201 # iperf3
      8080 # typical http dev server
    ];
  };
}
