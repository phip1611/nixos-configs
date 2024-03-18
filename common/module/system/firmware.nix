{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.system;
in
{
  config = lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfree = true;
    hardware.enableAllFirmware = true;
    hardware.enableRedistributableFirmware = true;
    services.fwupd.enable = true;
  };
}
