{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.user-env;
  username = config.phip1611.username;
in
{
  config = lib.mkIf (cfg.enable && cfg.withGui) {
    # Teamviewer GUI doesn't work without the daemon.
    services.teamviewer.enable = true;

    users.users."${username}".packages = (with pkgs; [
      teamviewer
    ]);
  };
}
