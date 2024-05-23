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
  # TODO temporarily disabled. Doesn't build with Linux 6.9 right now. Wait for
  # nixpkgs update.
  # virtualisation.virtualbox.host.enable = true;
}
