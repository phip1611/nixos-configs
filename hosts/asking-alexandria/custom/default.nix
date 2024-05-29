{ config, lib, pkgs, ... }:

{
  imports = [
    ../../../profiles/server.nix

    ./nginx.nix

    # Hosted web projects
    ./dd-systems-meetup.nix
    ./img-to-webp-service.nix
    ./netdata.nix
    ./wambo-web.nix
  ];

  config = {
    phip1611 = {
      common = {
        user-env = {
          username = "phip1611";
          git.username = "Philipp Schuster";
          git.email = "phip1611@gmail.com";
        };
      };
    };

    # My server obtains a IPv4 address by DHCP but not an IPv6 address. For IPv6,
    # Netcup only provides me a "2a03:4000:53:f7f::/64" net. I pick one IP and
    # configure it:
    networking.interfaces."ens3" = {
      useDHCP = true; # obtain IPv4 address
      ipv6.addresses = [
        {
          address = "2a03:4000:53:f7f::1";
          prefixLength = 64;
        }
      ];
    };
  };
}
