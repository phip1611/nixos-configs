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
          enable = true;
          withDevCAndRust = false;
          withDevJava = false;
          withDevJavascript = false;
          withDevNix = false;
          withGui = false;
          withMedia = false;
          withPerf = true;
          withPkgsJ4F = false;
          withVmms = false;
        };

        system = {
          enable = true;
          withAutoUpgrade = true;
          withNixVerifyStoreService = true;
          # Originally I deactivated this with "security ftw!" in mind. But
          # in November I experienced that buildNpmPackage of the wambo-web
          # flake failed in Linux 6.6, probably due to io_uring issues. With
          # 6.11, everything is fine.
          # TODO: Go back to LTS 6.12, once it is released!
          withBleedingEdgeLinux = true;
          withDocker = false;
        };
      };
      nix-binary-cache.enable = true;
    };

    # Comes with a pre-configured configuration for ssh.
    services.fail2ban.enable = true;

    nix = {
      # Safe some disk space.
      settings = {
        keep-outputs = lib.mkForce false;
        keep-derivations = lib.mkForce false;
      };
    };
  };
}
