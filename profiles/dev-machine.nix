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
    users.users.${config.phip1611.common.user-env.username}.extraGroups = [
      "dialout" # use serial interfaces(e.g. via minicom) without sudo
    ];

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
          withBootscreen = true;
          withDockerRootless = true;
          withSecureDns = true;
        };
      };
      nix-binary-cache.enable = true;
      services = {
        flake-prefetch.enable = true;
        zsh-history-backup.enable = true;
      };
    };

    nix = {
      gc.options = "--delete-older-than 14d";
      # Keep nix store populated for no/little wait times during typical work
      settings = {
        keep-outputs = true;
        keep-derivations = true;
      };
    };
  };
}
