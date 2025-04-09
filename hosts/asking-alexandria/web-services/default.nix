{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./nginx.nix

    # Hosted web projects
    ./de.wambo-web
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

    # Turn stuff on that is deactivated by the server profile. This is not
    # a regular server but one where we want to have a fully populated Nix
    # store.
    nix = {
      settings = {
        keep-outputs = lib.mkForce true;
        keep-derivations = lib.mkForce true;
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
