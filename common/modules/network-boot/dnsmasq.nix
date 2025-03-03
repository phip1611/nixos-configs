# services.dnsmasq used for DHCP and TFTP. If a machine connected to the
# specified performs network boot, dnsmasq will reply to that request.

{
  config,
  pkgs,
  lib,
  ...
}:

let
  networksByInterface = config.phip1611.network-boot;
  interfaceNames = builtins.attrNames networksByInterface;

  hostIPs = map (n: n.hostIp) (builtins.attrValues networksByInterface);

  ipxeNetworkBoot = pkgs.callPackage ./ipxe.nix { };
  ipxeBios = "ipxe.kpxe";
  ipxeEfi = "ipxe.efi";
  ipxeDefaultCfgFile = ipxeNetworkBoot.passthru.defaultCfgFile;
in
{
  config = lib.mkIf (networksByInterface != { }) {
    # Ensure that the directory is created, if it doesn't exist.
    # Only relevant when a new NixOS machine is initially set up.
    systemd.services.dnsmasq.preStart =
      let
        tftpDirSetupLines = lib.pipe networksByInterface [
          (lib.mapAttrsToList (
            (_interface: network: ''
              echo "Creating tftp-root=${network.tftpRoot} if it doesn't exist ..."
              mkdir -m 0777 -p ${network.tftpRoot}

              replace_if_not_exists ${ipxeNetworkBoot}/ipxe.efi ${network.tftpRoot}/${ipxeEfi}
              # For legacy BIOS network boot.
              replace_if_not_exists ${ipxeNetworkBoot}/undionly.kpxe ${network.tftpRoot}/${ipxeBios}
              replace_if_not_exists ${./ipxe.md} ${network.tftpRoot}/ipxe.md
              replace_if_not_exists ${./ipxe-default.cfg} ${network.tftpRoot}/${ipxeDefaultCfgFile}
            '')
          ))
          (builtins.concatStringsSep "\n")
        ];
      in
      ''
        replace_if_not_exists() {
          file=$1
          dest=$2

          if ! [ -f "$dest" ]; then
            echo installing "$file" to "$dest"
            install -m 0777 "$file" "$dest"
          fi
        }

        ${tftpDirSetupLines}
      '';

    services.dnsmasq =
      let
        # Specify the file the DHCP/BOOTP client should load via TFTP next.
        dhcpBootLines =
          map (hostIp: "tag:efi-x86_64,${ipxeEfi},${hostIp}") hostIPs
          ++ map (hostIp: "tag:legacy-x86,${ipxeBios},${hostIp}") hostIPs;

        dhcpRangeLines = lib.mapAttrsToList (
          interface: network: "${interface},${network.dhcpRange.from},${network.dhcpRange.to},infinite"
        ) networksByInterface;

        tftpRootLines = lib.mapAttrsToList (
          interface: network: "${network.tftpRoot},${interface}"
        ) networksByInterface;
      in
      {
        enable = true;

        # Only operate on specified interfaces.
        # Setting this to true breaks "ping google.de" and all other DNS
        # requests on the host.
        resolveLocalQueries = false;

        # Configuration reference:
        # https://github.com/imp/dnsmasq/blob/master/dnsmasq.conf.example
        #
        # nixpkgs automatically creates multiple lines from an array, as
        # expected by dnsmasq.
        settings =
          {
            # 0 => disable DNS; we only need DHCP and TFTP
            port = 0;
            domain-needed = true;
            bogus-priv = true;

            # Prevent reading dnsmasq /etc/resolv.conf, as we do not use the DNS
            # functionality at all.
            no-resolv = true;

            # Listen for DHCP/BOOTP requests on these interfaces.
            interface = interfaceNames;

            # The interface might not be always connected and only only available
            # eventually, e.g., when connecting a docking station.
            # => Don't "bind-interface = true"
            bind-dynamic = true;

            # Don't cache nothing.
            cache-size = 0;

            # TODO match also non efi etc
            dhcp-match = "set:efi-x86_64,option:client-arch,7";
            dhcp-boot = dhcpBootLines;

            # Answer DHCP requests with given IPv4 addresses:
            dhcp-range = dhcpRangeLines;
          }
          // lib.attrsets.optionalAttrs (lib.lists.length tftpRootLines > 0) {
            # Serve network boot files.
            enable-tftp = true;
            tftp-root = tftpRootLines;
          };
      };
  };
}
