{ config, lib, pkgs, ... }:

{
  users.users.pschuster = {
    packages = with pkgs; [
      libreoffice
    ];
  };

  # Add Vanilla VBox.
  virtualisation.virtualbox.host.enable = true;
}
