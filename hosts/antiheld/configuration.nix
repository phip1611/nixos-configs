# This configuration file is (almost) the one with that I set up the raspberry
# pi. It is based on this guide:
# https://nix.dev/tutorials/nixos/installing-nixos-on-a-raspberry-pi.html

{ config, lib, pkgs, ... }:

let
  user = "phip1611";
in
{
  imports = [
    ./custom
  ];

  boot = {
    kernelPackages = lib.mkForce pkgs.linuxKernel.packages.linux_rpi4;
    initrd.availableKernelModules = [
      "xhci_pci"
      "usbhid"
      "usb_storage"
    ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  environment.systemPackages = with pkgs;
    [
      libraspberrypi
      raspberrypi-eeprom

      micro
    ];

  services.openssh.enable = true;
  services.openssh.ports = lib.mkForce [ 7331 ];

  users = {
    users."${user}" = {
      isNormalUser = true;
      extraGroups = [ "wheel" "gpio" ];
    };
  };

  console.keyMap = "de";
  system.stateVersion = "23.11"; # Did you read the comment?

}

