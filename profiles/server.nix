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
          # Prefer stability and security
          withBleedingEdgeLinux = lib.mkDefault false;
          withSecureDns = lib.mkDefault true;
        };
      };
      nix-binary-cache.enable = lib.mkDefault true;
    };

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
