{ config, lib, pkgs, ... }:

{
  users.users.pschuster = {
    isNormalUser = true;
    description = "Philipp Schuster";
    extraGroups = [
      "dialout" # access (USB) serial devices without sudo
      "networkmanager"
      "wheel"
    ];
  };
}
