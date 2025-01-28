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
          # Originally I deactivated this with "security ftw!" in mind. But
          # in November I experienced that buildNpmPackage of the wambo-web
          # flake failed in Linux 6.6, probably due to io_uring issues. With
          # 6.11, everything is fine.
          # TODO: Go back to LTS 6.12, once it is released!
          withBleedingEdgeLinux = lib.mkDefault true;
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
