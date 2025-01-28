{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.phip1611.network-boot;

  username = config.phip1611.username;

  # Name of the ipxe EFI binary in the tftp root.
  ipxeEfi = "ipxe.efi";
  # Name of the ipxe legacy binary in the tftp root.
  ipxeBios = "ipxe.kpxe";
  # Info file for the tftp boot dir.
  ipxeMd = ./ipxe.md;
  # Default ipxe config.
  ipxeDefaultCfg = ./ipxe-default.cfg;

  # Folds the provided list with the provided callback to an attribute set.
  # The mapEntry function must map a list entry to an attribute set.
  fold =
    # mapEntry :: any(list-item) -> attrset
    mapEntry: list:
    builtins.foldl' (acc: item: (mapEntry item) // acc) { } # accumulator
      list;

  # List with `cfg.interfaces` entries, which have a hostnameAlias set
  interfacesWithHost = builtins.filter (
    interface: builtins.hasAttr "hostnameAlias" interface
  ) cfg.interfaces;
  # List with just interface names from the `cfg.interfaces` entries.
  interfaceNames = map (interface: interface.interface) cfg.interfaces;
  # List with host IPs.
  hostIPs = map (interface: interface.hostIp) cfg.interfaces;
in
{
  options = {
    phip1611.network-boot = {
      enable = lib.mkEnableOption "Enable the necessary network boot services and interface configurations";

      interfaces = lib.mkOption {
        type = lib.types.listOf (lib.types.attrsOf lib.types.str);
        description = "Network interface configurations";
        example = [
          {
            interface = "enp4s0";
            # The IP of the interface on the host.
            hostIp = "192.168.44.100";
            # The IP that the test box will obtain via DHCP.
            testboxIp = "192.168.44.101";
            # [Optional] Alias to the device in /etc/hosts
            hostnameAlias = "testbox";
          }
        ];
      };

      username = lib.mkOption {
        type = lib.types.str;
        description = "Username that is the owner of all files in the tftproot directory";
        example = "myuser";
        default = null;
      };

      # Root directory for the tftpboot. Automatically created by the dnsmasq
      # service on startup, if it doesn't exist.
      #
      # There was a long pain story trying to enable "~/tftpboot", but no tftp
      # server (also others than dnsmasq) wanted to serve from that. There
      # always have been permission issues.
      #
      # ⚠ Additionally, symlinks into the home directory are not working.
      # All files need to be placed directly in this directory.
      tftpRoot = lib.mkOption {
        type = lib.types.str;
        description = "Absolute TFTP root path in the host";
        default = "/tftpboot";
        example = "/tftpboot";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (import ./overlay.nix)
    ];

    # Ignore all those interfaces in the (graphical) GNOME network manager.
    networking.networkmanager.unmanaged = interfaceNames;

    systemd.network.wait-online = {
      # I use network boot on portable machines. At least on one machine, I
      # use the ethernet port of a docking station. As a consequence, with
      # this setting, the boot will not be delayed by 90 seconds, when the
      # interface is not found.
      anyInterface = true;
      ignoredInterfaces = interfaceNames;
    };

    # Create an extra entry in /etc/hosts per interface.
    # This enables to `ssh user@hostname` into the machine, for example.
    networking.extraHosts =
      let
        # Create entries in the  /etc/hosts
        entries = map (line: "${line.testboxIp} ${line.hostnameAlias}") interfacesWithHost;
      in
      builtins.concatStringsSep "\n" entries;

    # Network setup per interface: assign IP and deactivate DHCP
    networking.interfaces =
      let
        # Function -> attribute set
        baseConfig = interface: {
          useDHCP = false;
          ipv4.addresses = [
            {
              address = interface.hostIp;
              # 24: 255.255.255.0
              prefixLength = 24;
            }
          ];
        };
      in
      fold (interface: ({
        "${interface.interface}" = baseConfig interface;
      })) cfg.interfaces;

    # Allow all relevant ports for convenient network boot setups.
    networking.firewall.interfaces =
      let
        baseConfig = {
          allowedUDPPorts = [
            53 # dns
            67 # dhcp/bootp (server)
            68 # dhcp/bootp (client)
            69 # tftp
          ];
          allowedTCPPorts = [
            22 # ssh
            80 # http - To enable ipxe to load files also via HTTP.
            8080 # http custom port
          ];
        };
      in
      fold (interface: {
        "${interface.interface}" = baseConfig;
      }) cfg.interfaces;

    # Additional dnsmasq setup. Prepare the tftproot directory.
    systemd.services.dnsmasq = lib.mkIf (cfg.username != null) {
      # Ensure that the directory is created, if it doesn't exist.
      # Only relevant when a new NixOS machine is initially set up.
      preStart = ''
        mkdir -m 0777 -p ${cfg.tftpRoot}

        function replace_if_not_exists() {
          file=$1
          dest_name=$2

          dest="${cfg.tftpRoot}/$dest_name"

          if ! [ -f "$dest" ]; then
            echo installing "$file" to "$dest"
            install -m 0755 -o ${cfg.username} "$file" "$dest"
          fi
        }

        replace_if_not_exists ${pkgs.ipxeNetworkBoot}/ipxe.efi ipxe.efi
        replace_if_not_exists ${pkgs.ipxeNetworkBoot}/ipxe.kpxe ipxe.kpxe
        replace_if_not_exists ${ipxeMd} ipxe.md
        replace_if_not_exists ${ipxeDefaultCfg} ipxe-default.cfg
      '';
    };

    # dnsmasq is used for DHCP and TFTP-Boot over the specified interfaces.
    # The testboxes must be configured to perform network boot, which results
    # in a DHCP/BOOTP request. dnsmasq will answer their replies.
    services.dnsmasq =
      let

        # Tells the network-boot client: load "ipxe.efi" via TFTP from the
        # TFTP server behind the specified IP.
        dhcpBootLines =
          map (hostIp: "tag:efi-x86_64,${ipxeEfi},${hostIp}") hostIPs
          ++ map (hostIp: "tag:legacy-x86,${ipxeBios},${hostIp}") hostIPs;

        dhcpRangeLines = map (
          interface: "${interface.interface},${interface.testboxIp},${interface.testboxIp},infinite"
        ) cfg.interfaces;

        tftpRootLines = map (interfaceName: "${cfg.tftpRoot},${interfaceName}") interfaceNames;
      in
      {
        enable = true;
        # Only operate on specified interfaces.
        # Setting this to true makes "ping google.de" etc. impossible.
        resolveLocalQueries = false;
        # Configuration reference:
        # https://github.com/imp/dnsmasq/blob/master/dnsmasq.conf.example
        #
        # Nix derivation automatically creates multiple lines from an array, as
        # expected by dnsmasq.
        settings = {
          # 0 => disable DNS; we only need DHCP and TFTP
          port = 0;
          domain-needed = true;
          bogus-priv = true;
          # prevent reading dnsmasq /etc/resolv.conf
          # (because we do not use the DNS functionality at all)
          no-resolv = true;

          # Listen for DHCP/BOOTP requests on these interfaces.
          interface = interfaceNames;

          # With "bind-interfaces" I always encountered the problem that
          # the required interface is not up yet when dnsmasq starts,
          # even tho I tried to fiddle with delay in the service
          # (to wait until network is online). However, this way it works.
          bind-dynamic = true;

          # don't cache nothing
          cache-size = 0;

          dhcp-match = "set:efi-x86_64,option:client-arch,7";
          dhcp-boot = dhcpBootLines;

          # Answer DHCP requests/assign IPv4 address:
          # Enables SSH and other things on the connected test box.
          dhcp-range = dhcpRangeLines;

          # Serve network boot files.
          enable-tftp = true;
          tftp-root = tftpRootLines;
        };
      };
  };
}
