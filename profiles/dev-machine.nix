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
          withBleedingEdgeLinux = true;
          withDocker = true;
        };
      };
    };
  };
}
