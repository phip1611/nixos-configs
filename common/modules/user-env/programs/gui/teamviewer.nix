{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.user-env;
in
{
  config = lib.mkIf (cfg.enable && cfg.withGui) {
    # Teamviewer GUI doesn't work without the daemon.
    services.teamviewer.enable = true;
    # Wait for https://github.com/NixOS/nixpkgs/pull/346365
    # services.teamviewer.package = pkgsUnstable.teamviewer;

    users.users."${cfg.username}".packages = [
      pkgs.teamviewer
    ];
  };
}
