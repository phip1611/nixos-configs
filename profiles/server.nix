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
      services.zsh-history-backup.enable = lib.mkDefault true;
    };

    # Latest LTS kernel
    boot.kernelPackages = pkgs.linuxPackages_6_12;

    # Comes with a pre-configured configuration for ssh.
    services.fail2ban.enable = lib.mkDefault true;

    # Shrink system closure size. Don't require perl.
    programs.command-not-found.enable = false;

    # We typically have fixed interface names in server-like setups.
    # Removing NetworkManager reduces the closure size by more than one GiB.
    networking.networkmanager.enable = false;

    nix = {
      # Save some disk space.
      settings = {
        keep-outputs = lib.mkDefault false;
        keep-derivations = lib.mkDefault false;
      };
    };
  };
}
