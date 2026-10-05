# nix-serve in the nixserve container. It serves the host's Nix store via the
# host's Nix daemon, whose socket is bind-mounted into every NixOS container.
#
# Reference: https://nixos.wiki/wiki/Binary_Cache
{
  pkgs,
  ...
}:

let
  backend = (import ../net.nix).backends.nixserve;
in
{
  services.nix-serve = {
    enable = true;
    # Only listen on the backend bridge, not on all addresses.
    bindAddress = backend.ipv4;
    inherit (backend) port;
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
    # Bind-mounted from the host.
    secretKeyFile = "/var/cache-priv-key.pem";
  };
}
