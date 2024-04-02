{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.user-env;
in
{
  config = lib.mkIf (cfg.enable && cfg.withGui) {
    # Teamviewer GUI doesn't work without the daemon.
    services.teamviewer.enable = true;

    users.users."${cfg.username}".packages = (with pkgs; [
      teamviewer
    ]);
  };
}
