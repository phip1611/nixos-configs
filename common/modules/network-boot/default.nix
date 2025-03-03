# NixOS module providing support for network boot.

{
  config,
  pkgs,
  lib,
  ...
}:

let
  networksByInterface = config.phip1611.network-boot;
  interfaceNames = builtins.attrNames networksByInterface;
in
{
  imports = [
    ./dnsmasq.nix
  ];

  options = {
    # Attribute set of interface to network definition.
    phip1611.network-boot = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (import ./network-options.nix { inherit config lib; })
      );
      default = {
        # Won't appear in nixos-option output when unspecified
        /*
          enp195s0f3u1c2 = {
            tftpRoot = "/srv/tftp";
            hostIp = "192.168.44.100";
            dhcpRange = {
              from = "192.168.44.101";
              to = "192.168.44.101";
            };
            hostnameAlias = "office-testbox";
          };
        */
      };
      description = ''
        An attribute set defining the interfaces used for network boot. On each
        interface, a DHCP/BOOTP service is active. It instructs a client to
        load a manually crafted ipxe version via TFTP, which then loads a
        configuration file from the specified tftp root.

        This gives you the freedom to place further files in the TFTP root
        directory, to control which files a connected machine should boot.

        Once a connected machine has an IP (either obtained or statically
        configured), you can also use SSH or other network services, if the
        other machine supports these services.

        This module uses `services.dnsmasq` as DHCP and TFTP server.
        `services.dnsmasq` can't be used for other purposes, when this module is
        used!
      '';
      example = {
        "eth0" = {
          tftpRoot = "/srv/tftp/"; # or null to deactivate network boot
          hostIp = "192.168.44.100";
          dhcpRange = {
            from = "192.168.44.101";
            to = "192.168.44.101";
          };
        };
      };
    };
  };

  config = lib.mkIf (networksByInterface != { }) {
    networking.networkmanager.unmanaged = interfaceNames;
    systemd.network.wait-online.ignoredInterfaces = interfaceNames;

    networking.extraHosts = lib.pipe networksByInterface [
      (lib.filterAttrs (_interface: network: network.hostnameAlias != null))
      (lib.mapAttrsToList (_interface: network: "${network.dhcpRange.from} ${network.hostnameAlias}"))
      (builtins.concatStringsSep "\n")
    ];

    # Set allowed ports in firewall.
    networking.firewall.interfaces = lib.concatMapAttrs (interface: network: {
      ${interface} = {
        inherit (network) allowedTCPPorts allowedUDPPorts;
      };
    }) networksByInterface;

    # Set static IP configuration per interface (for the host).
    networking.interfaces =
      let
        baseConfig = network: {
          useDHCP = false;
          ipv4.addresses = [
            {
              address = network.hostIp;
              # 24: 255.255.255.0
              prefixLength = 24;
            }
          ];
        };
      in
      lib.concatMapAttrs (interface: network: {
        ${interface} = baseConfig network;
      }) networksByInterface;
  };
}
