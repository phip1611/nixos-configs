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
      1337 # for misc fun stuff
      5201 # iperf3
    ];

    # Use a different MAC address per Wi-Fi network, so that networks and
    # their operators can't track the machine across locations. Unlike
    # "stable", the address is derived from the SSID, not from the connection
    # profile. It stays the same when I forget and re-add a network, so DHCP
    # reservations keep working.
    networking.networkmanager.wifi.macAddress = "stable-ssid";

    # Recommended by the docs. Also, I had so often trouble with a failing
    # wait-online service, although everything was operating properly.
    # Therefore, lets deactivate it.
    systemd.network.wait-online.enable = !config.networking.networkmanager.enable;

    # Apply the `networking.*` options to systemd-networkd.
    # This is a more modern implementation and likely soon the default.
    networking.useNetworkd = true;
  };
}
