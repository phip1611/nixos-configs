# Developer machine configuration.
#
# Intended for manual updates and frequent active activity from myself.


{ config, lib, pkgs, ... }:

{
  config = {
    phip1611 = {
      common = {
        user-env = {
          enable = true;
        };
        system = {
          enable = true;
          withAutoUpgrade = false;
        };
      };
    };
  };
}
