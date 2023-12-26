{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.system.latest-linux;
in
{
  options = {
    phip1611.common.system.latest-linux = {
      enable = lib.mkEnableOption "Use the latest stable Linux kernel";
    };
  };

  config = lib.mkIf cfg.enable {
    # Use latest stable kernel.
    boot.kernelPackages = pkgs.linuxPackages_latest;
  };
}
