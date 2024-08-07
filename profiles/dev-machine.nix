# Developer machine configuration.
#
# Intended for my developer machines. NixOS updates are not performed
# automatically.

{ config, lib, pkgs, ... }:

{
  config = {
    phip1611 = {
      bootitems.enable = true;
      common = {
        user-env = {
          enable = true;
        };
        system = {
          enable = true;
          withAutoUpgrade = false;
          withDocker = true;
        };
      };
    };

    # Prevent frequent "/boot volume full" errors. Limit this to a sane small
    # number.
    boot.loader.grub.configurationLimit = 7;
    boot.loader.systemd-boot.configurationLimit = 7;
  };
}
