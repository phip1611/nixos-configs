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
          withBootitems = false;
          withDevCAndRust = false;
          withDevJava = false;
          withDevJavascript = false;
          withDevNix = false;
          withGui = false;
          withMedia = false;
          withPkgsJ4F = false;
          withVmms = false;
        };

        system = {
          enable = true;
          withAutoUpgrade = true;
          withDocker = false;
        };
      };
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
