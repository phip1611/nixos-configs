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
        };
      };
    };
  };
}
