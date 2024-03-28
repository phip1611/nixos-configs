{ config, lib, pkgs, ... }:

let
  username = config.phip1611.username;
  cfg = config.phip1611.common.user-env;
in
{
  config = lib.mkIf (cfg.enable) {
    nix.settings.trusted-users = [ username ];
  };
}
