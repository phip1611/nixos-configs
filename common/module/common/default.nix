# Common Configurations for my NixOS systems.

{ lib, config, options, ... }:

let
  cfg = config.phip1611.common;
in
{
  imports = [
    ./system
    ./user
  ];

  options.phip1611.common = {
    # I use mkOption in favor of mkEnableOption as I want this attribute
    # to be default-true.
    enable = lib.mkOption {
      type = lib.types.bool;
      description = "Enable all common sub-modules at once";
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    phip1611.common.user.enable = true;
    phip1611.common.system.enable = true;
  };

}
