# Hosts the binary cache with the artifacts of this project/repository.
#
# Reference: https://nixos.wiki/wiki/Binary_Cache

{
  config,
  lib,
  pkgs,
  ...
}:

let
  commonCfg = import ../nginx-common-host-config.nix;
in
{
  imports = [
    ./ci-user.nix
  ];

  config = {
    # All but the Host hosting the cache itself should use it. Deactivate it.
    phip1611.nix-binary-cache.enable = lib.mkForce false;

    services.nginx.virtualHosts."nix-binary-cache.phip1611.dev" = commonCfg // {
      locations."/".proxyPass = with config.services.nix-serve; "http://${bindAddress}:${toString port}";
    };

    services.nix-serve = {
      enable = true;
      # Drop-in replacement on steroids
      # https://github.com/aristanetworks/nix-serve-ng
      package = pkgs.nix-serve-ng.overrideAttrs (old: {
        # I reduce the default priority of 30 by setting it to 100
        # (higher value => lower priority). This way, the default NixOS cache,
        # which has a priority of 40, is always preferred over my own cache.
        patches = (old.patches or [ ]) ++ [
          ./nix-serve-ng-reduce-priority.patch
        ];
      });
      secretKeyFile = "/var/cache-priv-key.pem";
    };
  };
}
