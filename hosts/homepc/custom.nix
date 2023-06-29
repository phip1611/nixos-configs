{ config, pkgs, lib, phip1611-common, home-manager, ... }:



{
  imports = [
    # Enables the "home-manager" configuration property
    home-manager.nixosModules.home-manager
    # Needs flake inputs "nixpkgs" and "nixpkgs-unstable".
    phip1611-common.nixosModules.phip1611-common
  ];

  networking.hostName = "homepc";

  # phip1611 dotfiles common NixOS module configuration
  phip1611 = {
    username = "phip1611";
    stateVersion = "23.05";
    common = {
      enable = true;
      user.env.git.username = "Philipp Schuster";
      user.env.git.email = "phip1611@gmail.com";
    };
    util-overlay.enable = true;
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
