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

  services.nginx.appendHttpConfig = ''
    # Add HSTS header with preloading to HTTPS requests.
    # Adding this header to HTTP requests is discouraged
    map $scheme $hsts_header {
        https   "max-age=31536000; includeSubdomains; preload";
    }
    add_header Strict-Transport-Security $hsts_header;

    # Minimize information leaked to other domains
    add_header 'Referrer-Policy' 'origin-when-cross-origin';

    # Disable embedding as a frame
    add_header X-Frame-Options DENY;

    # Prevent injection of code in other mime types (XSS Attacks)
    add_header X-Content-Type-Options nosniff;
  '';

  security.acme = {
    acceptTerms = true;
    defaults.email = "phip1611@gmail.com";
  };
}
