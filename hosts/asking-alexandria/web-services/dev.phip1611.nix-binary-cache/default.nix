# Hosts the binary cache with the artifacts of this project/repository.
#
# Reference: https://nixos.wiki/wiki/Binary_Cache

{ config, lib, pkgs, ... }:

{
  imports = [
    ./ci-user.nix
  ];

  config = {
    # All but the Host hosting the cache itself should use it. So deactivate it.
    phip1611.common.system.withSelfBinaryCache = false;

    services.nginx.virtualHosts."nix-binary-cache.phip1611.dev" = {
      enableACME = true;
      http2 = true;
      http3 = true;
      quic = true; # also needed when http3 = true
      # Upgrade HTTP to HTTPS
      forceSSL = true;
      locations."/".proxyPass = with config.services.nix-serve; "http://${bindAddress}:${toString port}";
    };

    services.nix-serve = {
      enable = true;
      secretKeyFile = "/var/cache-priv-key.pem";
    };
  };
}
