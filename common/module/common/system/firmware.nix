{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.system.firmware;
in
{
  options = {
    phip1611.common.system.firmware.enable = lib.mkEnableOption "Enable all firmware settings and microcode/firmware updates";
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfree = true;
    hardware.enableAllFirmware = true;
    hardware.enableRedistributableFirmware = true;
    services.fwupd.enable = true;
  };
}
