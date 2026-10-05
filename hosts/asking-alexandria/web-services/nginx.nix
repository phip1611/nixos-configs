{
  config,
  lib,
  pkgs,
  ...
}:

let
  #pkgsUnstable = import inputs.nixpkgs-unstable {
  #  system = pkgs.stdenv.hostPlatform.system;
  #};
in
{
  # /var/lib/acme/.challenges must be writable by the ACME user
  # and readable by the Nginx user. The easiest way to achieve
  # this is to add the Nginx user to the ACME group.
  users.users.nginx.extraGroups = [ "acme" ];

  services.nginx.enable = true;
  # TODO reintroduce once nginx derivation from stable is compatible again
  # (in 26.11?). Caused by https://github.com/NixOS/nixpkgs/pull/545717.
  # services.nginx.package = pkgsUnstable.nginx;

  services.nginx.recommendedOptimisation = true;
  services.nginx.recommendedTlsSettings = true;
  # Forwarded headers.
  services.nginx.recommendedProxySettings = true;

  services.nginx.recommendedBrotliSettings = true;
  services.nginx.recommendedGzipSettings = true;

  services.nginx.serverNamesHashBucketSize = 128;

  # Reject requests for unknown host names, e.g., from scanners that only know
  # the IP, instead of serving them by the first vhost. `rejectSSL` aborts the
  # TLS handshake, so no certificate reveals the hosted domains. QUIC makes
  # this the default for HTTP/3 as well.
  services.nginx.virtualHosts."_" = {
    default = true;
    rejectSSL = true;
    quic = true;
    locations."/".return = "444";
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "phip1611@gmail.com";
  };
}
