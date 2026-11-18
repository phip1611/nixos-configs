# Monitors the health of all disks via S.M.A.R.T. and warns about failing
# disks before they die.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.phip1611.common.system;
in
{
  config = lib.mkIf cfg.enable {
    services.smartd = {
      enable = true;
      # Show warnings as desktop notifications. The default X11 notification
      # (xmessage) doesn't reach a Wayland session.
      notifications.systembus-notify.enable = config.services.displayManager.enable;
      notifications.x11.enable = false;
    };

    # Virtual disks have no S.M.A.R.T. data, and smartd fails if it finds no
    # device to monitor.
    systemd.services.smartd.unitConfig.ConditionVirtualization = "no";
  };
}
