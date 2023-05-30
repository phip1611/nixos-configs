{ config, pkgs, user, ... }:

{
  users.users.phip1611 = {
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
