# Server configuration.
#
# Intended for auto-update and rare active activity from myself.

{ config, lib, pkgs, ... }:

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
          # Security and stability ftw.
          withBleedingEdgeLinux = false;
          withDocker = false;
        };
      };
      nix-binary-cache.enable = true;
    };

    # Comes with a pre-configured configuration for ssh.
    services.fail2ban.enable = true;

    networking.firewall.allowPing = true;
    networking.firewall.rejectPackets = true;

    nix = {
      # Safe some disk space.
      settings = {
        keep-outputs = lib.mkForce false;
        keep-derivations = lib.mkForce false;
      };
    };
  };
}
