# Entry point into the configuration.

{ config, lib, pkgs, ... }:

let
  # This is the version that I used to initially install my system. As
  # recommended by the docs, its okay to leave this property in its initial
  # value.
  stateVersion = "22.11";
in
{
  imports = [
    ./modules/user
    ./modules/boot.nix
    ./modules/general-nixos.nix
    ./modules/hardware-configuration.nix
    ./modules/i18n.nix
    ./modules/networking.nix
    ./modules/sound.nix
    ./modules/systemd.nix
    ./modules/xserver.nix
  ];

  # phip1611 dotfiles common NixOS module configuration
  phip1611 = {
    username = "pschuster";
    common = {
      # Enable all default options.
      enable = true;
      user-env.git.username = "Philipp Schuster";
      user-env.git.email = "philipp.schuster@cyberus-technology.de";
    };
    services.meshcommander.enable = true;
  };

  fonts.packages = [
    pkgs.dancing-script
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = stateVersion; # Did you read the comment?

}
