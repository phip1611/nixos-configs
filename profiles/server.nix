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
          enable = true;
        };

        system = {
          enable = true;
          withAutoUpgrade = true;
          withNixVerifyStoreService = true;
          # Stability is king
          withBleedingEdgeLinux = false;
          withSecureDns = true;
        };
      };
      nix-binary-cache.enable = true;
      services.zsh-history-backup.enable = true;
    };

    # Latest LTS kernel
    boot.kernelPackages = pkgs.linuxPackages_6_12;

    # Comes with a pre-configured configuration for ssh.
    services.fail2ban.enable = true;

    # Shrink system closure size. Don't require perl.
    programs.command-not-found.enable = false;

    # We typically have fixed interface names in server-like setups.
    # Removing NetworkManager reduces the closure size by more than one GiB.
    networking.networkmanager.enable = false;

    xdg = {
      autostart.enable = false;
      icons.enable = false;
      mime.enable = false;
      sounds.enable = false;
    };

    nix = {
      # Save some disk space.
      settings = {
        keep-outputs = false;
        keep-derivations = false;
      };
    };
  };
}
