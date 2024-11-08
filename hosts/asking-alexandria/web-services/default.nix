{ config, lib, pkgs, ... }:

{
  imports = [
    ../../../profiles/server.nix

    ./nginx.nix

    # Hosted web projects
    # ./de.wambo-web temporarily deactivated as it doesn't build in Linux 6.6
    ./dev.phip1611.monitor/netdata.nix
    ./dev.phip1611.nix-binary-cache
    ./dev.phip1611.webp/img-to-webp-service.nix
    ./org.ukvly/dd-systems-meetup.nix
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
    # Netcup provides me an IPv6 "/64" net. I picked the first possible IP.
    networking.interfaces."ens3" = {
      useDHCP = true; # obtain IPv4 address
      ipv6.addresses = [
        {
          address = "2a03:4000:63:d3::1";
          prefixLength = 64;
        }
      ];
    };
  };
}
