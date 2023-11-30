{ config, pkgs, user, ... }:

{
  users.users.phip1611 = {
    isNormalUser = true;
    description = "Philipp Schuster";
    extraGroups = [
      "dialout" # access (USB) serial devices without sudo
      "networkmanager"
      "wheel"
    ];
  };
}
