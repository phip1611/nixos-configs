{ config, lib, pkgs, ... }:

{
  users.users.pschuster = {
    packages = with pkgs; [
      element-desktop

      # Nextcloud sets up a background service automatically.
      nextcloud-client
      zoom-us

      libreoffice-qt
    ];
  };

  # Add Vanilla VBox.
  virtualisation.virtualbox.host.enable = true;
}
