{ config, lib, pkgs, ... }:

{
  # phip1611 dotfiles common NixOS module configuration
  phip1611 = {
    username = "phip1611";
    common = {
      user-env = {
        enable = true;
        git.username = "Philipp Schuster";
        git.email = "phip1611@gmail.com";
      };

      system = {
        enable = true;
      };
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
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
}
