{ config, lib, pkgs, ... }:

{
  imports = [
    ../../profiles/dev-machine.nix
  ];

  phip1611 = {
    common = {
      user-env = {
        username = "phip1611";
        git.username = "Philipp Schuster";
        git.email = "phip1611@gmail.com";
      };
    };
  };

  # TPLink T3U WiFi USB Dongle
  # Unfortunately, this is buggy and only works sometimes. Reboots help.
  boot.kernelModules = [
    # The name of the module build by `kernelPackages.rtl88x2bu`.
    # See https://github.com/morrownr/88x2bu-20210702/blob/main/Makefile
    "88x2bu"
  ];
  boot.extraModulePackages = [
    config.boot.kernelPackages.rtl88x2bu
  ];

  # The required external driver (no upstream driver) does not (always)
  # compile for the latest kernel.
  # boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
}
