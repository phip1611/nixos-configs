# Developer machine configuration.
#
# Intended for my developer machines. NixOS updates are not performed
# automatically.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = {
    phip1611 = {
      bootitems.enable = true;
      common = {
        user-env = {
          enable = true;
          withDevCAndRust = true;
          withDevJava = true;
          withDevJavascript = true;
          withDevNix = true;
          withGui = true;
          withMedia = true;
          withPkgsJ4F = true;
          withVmms = true;
        };
        system = {
          enable = true;
          withBleedingEdgeLinux = true;
          withDockerRootless = true;
          withSecureDns = true;
        };
      };
      nix-binary-cache.enable = true;
      services.zsh-history-backup.enable = true;
    };

    nix = {
      # Keep nix store populated for no/little wait times during typical work
      settings = {
        keep-outputs = true;
        keep-derivations = true;
      };
    };
  };
}
