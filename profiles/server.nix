# Server configuration.
#
# Intended for auto-update and rare active activity from myself.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = {
    phip1611 = {
      common = {
        user-env = {
          # Only basics, no bloat in PATH.
          enable = lib.mkDefault true;
        };

        system = {
          enable = lib.mkDefault true;
          withAutoUpgrade = lib.mkDefault true;
          withNixVerifyStoreService = lib.mkDefault true;
          # Stability is king
          withBleedingEdgeLinux = false;
          withSecureDns = lib.mkDefault true;
        };
      };
      nix-binary-cache.enable = lib.mkDefault true;
    };

    # Latest LTS kernel
    boot.kernelPackages = pkgs.linuxPackages_6_12;

    # Comes with a pre-configured configuration for ssh.
    services.fail2ban.enable = lib.mkDefault true;

    nix = {
      # Save some disk space.
      settings = {
        keep-outputs = lib.mkDefault false;
        keep-derivations = lib.mkDefault false;
      };
    };
  };
}
