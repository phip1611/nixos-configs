{ config, pkgs, lib, ... }:

let
  cfg = config.networking;
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
        List of local test networks. A test network is not connected to the
        internet intended for connections between the host and a connected
        machine.
      '';
      example = {
        office-testbox = {
          enableDhcp = true;
          enableNetworkBoot = true;
          hostIp = "192.168.44.100";
          # Single IP.
          dhcpRange = [ "192.168.44.101" "192.168.44.101" ];
        };
      };
    };
  };

  config = { };
}
