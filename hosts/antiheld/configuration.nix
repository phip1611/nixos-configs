# This configuration file is (almost) the one with that I set up the raspberry
# pi. It is based on this guide:
# https://nix.dev/tutorials/nixos/installing-nixos-on-a-raspberry-pi.html

{
  config,
  lib,
  pkgs,
  ...
}:

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

  # https://github.com/NixOS/nixpkgs/issues/344963
  boot.initrd.systemd.tpm2.enable = false;

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom

    micro
  ];

  services.openssh.enable = true;
  services.openssh.ports = lib.mkForce [ 7331 ];

  users = {
    users."${user}" = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "gpio"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGZ1CsDfB8Bsg8H82oIgVjv8bu5KEh4UX5iqEfC+4hzF pschuster@xps13-pschuster"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIByFlysjuSdICGBaDUYOq5wPSPQgPWOenBwal2PhBtd pschuster@phips-framework13"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGNxAVKUnHxu8yL1MNUeIJkeuPyJqg89++A+rOydyZJi phip1611@homepc"
      ];
    };
  };

  console.keyMap = "de";
  system.stateVersion = "23.11"; # Did you read the comment?

}
