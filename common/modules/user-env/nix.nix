{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.phip1611.common.user-env;
in
{
  config = lib.mkIf cfg.enable {
    nix.settings.trusted-users = [ cfg.username ];
  };
}
