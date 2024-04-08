{ config, lib, ... }:

with lib;
{
  options = {
    dhcpRange = mkOption {
      type = types.attrs;
      description = ''
        DHCP IP range for the interface in a /24 net. `to` must not be less than
        `from`.

        This should be in the same net as `hostIp`.
      '';
      default = {
        from = "192.168.44.101";
        to = "192.168.44.101";
      };
      example = {
        from = "192.168.44.101";
        to = "192.168.44.101";
      };
    };

    hostIp = mkOption {
      type = types.nonEmptyStr;
      description = ''
        Host IP for the interface in a /24 net.

        This should be in the same net as `dhcpRange`.
      '';
      default = "192.168.44.100";
    };

    hostnameAlias = mkOption {
      type = types.nullOr types.nonEmptyStr;
      description = ''
        Entry in /etc/hosts pointing to the first IP in `dhcpRange`.

        This enables to `ssh user@hostname` into the machine, for example.
      '';
      example = "office-testbox";
      default = null;
    };

    allowedTCPPorts = mkOption {
      type = types.listOf types.port;
      description = ''
        List of TCP ports to open on that interface (host firewall).
      '';
      default = [
        22 # ssh
        80 # http
        443 # https
        5201 # iperf3

        # often used for local http services
        3000
        8000
        8080
      ];
    };

    allowedUDPPorts = mkOption {
      type = types.listOf types.int;
      description = ''
        List of UDP ports to open on that interface (host firewall).
      '';
      default = [
        53 # dns
        67 # dhcp/bootp (server)
        68 # dhcp/bootp (client)
        69 # tftp (network boot)
      ];
    };

    tftpRoot = mkOption {
      type = types.path;
      description = "Root path for TFTP on the host, typically used to serve network boot requests.";
      default = "/srv/tftp";
    };
  };
}
