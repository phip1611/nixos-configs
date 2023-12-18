{ config, lib, pkgs, ... }:

{
  # phip1611 dotfiles common NixOS module configuration
  phip1611 = {
    username = "phip1611";
    common = {
      enable = true;
      user.env.git.username = "Philipp Schuster";
      user.env.git.email = "phip1611@gmail.com";
    };
  };

  # TPLink T3U WiFi USB Dongle
  # Unfortunately, this is buggy and only works sometimes. Reboots help.
  boot.kernelModules = [
    "88x2bu"
  ];
  boot.extraModulePackages = [
    config.boot.kernelPackages.rtl88x2bu
  ];

  # The required external driver (no upstream driver) does not (always)
  # compile for the latest kernel.
  # phip1611.common.system.latest-linux.enable = lib.mkForce false;

}
