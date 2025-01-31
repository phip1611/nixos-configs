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
  config = lib.mkIf cfg.enable {
    # Improve network analysis.
    networking.firewall.allowPing = true;
    networking.firewall.rejectPackets = true;

    networking.firewall.allowedTCPPorts = [
      5201 # iperf3
      8080 # typical http dev server
    ];

    # Recommended by the docs. Also, I had so often trouble with a failing
    # wait-online service, although everything was operating properly.
    # Therefore, lets deactivate it.
    systemd.network.wait-online.enable = !config.networking.networkmanager.enable;

    # Apply the `networking.*` options to systemd-networkd.
    # This is a more modern implementation and likely soon the default.
    networking.useNetworkd = true;
  };
}
