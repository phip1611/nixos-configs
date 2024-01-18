# Miscellaneous configurations.

{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.system.misc;
in
{
  options = {
    phip1611.common.system.misc = {
      enable = lib.mkEnableOption "Enable other common system-wide options";
    };
  };

  config = lib.mkIf cfg.enable {
    # Don't accumulate crap.
    boot.tmp.cleanOnBoot = true;
    services.journald.extraConfig = ''
      SystemMaxUse=250M
      SystemMaxFileSize=50M
    '';

    # zram swap seems to enable a quicker and more responsive system when
    # memory usage is high.
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 25;
    };
  };
}
