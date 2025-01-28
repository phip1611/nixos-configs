# Sets up docker.

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
    # This has some limitations but for my limited use-case, this is fine.
    # I can build and run most basic docker containers.
    # More info: https://docs.docker.com/engine/security/rootless/
    virtualisation.docker.rootless = {
      enable = cfg.withDocker;
      # Sets SOCKER_HOST variable to the rootless Docker instance for normal
      # users by default.
      setSocketVariable = true;
    };
  };
}
