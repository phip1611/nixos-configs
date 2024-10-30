{ config, lib, pkgs, ... }@inputs:

let
  pkgsUnstable = import inputs.nixpkgs-unstable {
    system = pkgs.system;
  };
in
{
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 ];
  };

  # /var/lib/acme/.challenges must be writable by the ACME user
  # and readable by the Nginx user. The easiest way to achieve
  # this is to add the Nginx user to the ACME group.
  users.users.nginx.extraGroups = [ "acme" ];

  services.nginx.enable = true;
  services.nginx.package = pkgsUnstable.nginxQuic;

  services.nginx.recommendedOptimisation = true;
  services.nginx.recommendedTlsSettings = true;
  # Forwarded headers.
  services.nginx.recommendedProxySettings = true;

  services.nginx.recommendedBrotliSettings = true;
  services.nginx.recommendedGzipSettings = true;
  services.nginx.recommendedZstdSettings = true;

  security.acme = {
    acceptTerms = true;
    defaults.email = "phip1611@gmail.com";
  };
}
