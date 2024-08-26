{ config, pkgs, lib, ... }:

let
  cfg = config.phip1611.local-networks;

   # List of networks.
  networks = builtins.attrValues cfg.networks;
in
{
  options = {
    phip1611.local-networks = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          import ./network-options.nix { inherit config lib; }
        )
      );
      description = ''
        List of local test networks. A test network is intented for connections
        between the host and a connected machine, usually done via a physical
        LAN/ethernet port.

        On that port, a DHCP server is started to establish the network. This
        way services such as Intel AMT, SSH, or Network boot (TFTP) can operate.

        This module uses `services.dnsmasq` as DHCP and TFTP server.
        `services.dnsmasq` can't be used for other purposes, when this module is
        active.

        This module is only active if at least one network is defined.
      '';
      example = {
        office-testbox = {
          tftpRoot = "/srv/tftproot/"; # or null to deativate network boot
          hostIp = "192.168.44.100";
          # Single IP.
          dhcpRange = [ "192.168.44.101" "192.168.44.101" ];
        };
      };
    };
  };

  config = lib.mkIf (lib.length networks > 0) {

  };
}
