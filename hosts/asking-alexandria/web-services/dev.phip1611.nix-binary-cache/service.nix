# nix-serve, which serves the binary cache with the artifacts of this
# project/repository.
#
# Reference: https://nixos.wiki/wiki/Binary_Cache
{
  pkgs,
  ...
}:

let
  net = import ../net.nix;
in
{
  services.nix-serve = {
    enable = true;
    port = net.ports.nixServe;
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
}
