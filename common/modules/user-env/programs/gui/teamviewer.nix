{ config, lib, pkgs, ... }@inputs:

let
  cfg = config.phip1611.common.user-env;
  pkgsUnstable = import inputs.nixpkgs-unstable {
    system = pkgs.system;
    config = {
      allowUnfree = true;
    };
  };
in
{
  config = lib.mkIf (cfg.enable && cfg.withGui) {
    # Teamviewer GUI doesn't work without the daemon.
    services.teamviewer.enable = true;

    users.users."${cfg.username}".packages = [
      pkgsUnstable.teamviewer
    ];
  };
}
