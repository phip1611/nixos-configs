{ config, lib, ... }:

with lib;
{
  options = {
    dhcpIpRange = mkOption {
      type = types.listOf types.str;
      description = ''
        DHCP IP range for the interface. The first element is
        the inclusive begin, the second element the inclusive end. The list must
        have exactly two elements.
      '';
      default = [ /* from */ "192.168.44.101" /* to */ "192.168.44.101" ];
    };

    interface = mkOption {
      type = types.str;
      description = ''
        Name of the interface on the host.
      '';
      example = "enp42s0";
    };

    hostIp = mkOption {
      type = types.str;
      description = ''
        Host IP for the interface.
      '';
      default = "192.168.44.100";
    };

    hostnameAlias = mkOption {
      type = types.str;
      description = ''
        Host name alias for /etc/hosts pointing the first IP of the `dhcpIpRange`.
      '';
      example = "office-testbox";
      default = "";
    };

    openTcpPorts = mkOption {
      type = types.listOf types.int;
      description = ''
        List of TCP ports for the firewall to open.
      '';
      default = [
        22 # ssh
        80 # http
        443 # https
        # often used for local http services
        3000
        8000
        8080
      ];
    };

    openUdpPorts = mkOption {
      type = types.listOf types.int;
      description = ''
        List of UDP ports for the firewall to open
      '';
      default = [
        53 # dns
        67 # dhcp/bootp (server)
        68 # dhcp/bootp (client)
        69 # tftp (network boot)
      ];
    };

    tftpRoot = mkOption {
      type = types.nullOr types.str;
      description = "TFTP root path on the host to serve network boot requests.";
      example = "/src/tftproot";
      default = null; # network boot disabled
      # default = "/tmp";
    };
  };
}
