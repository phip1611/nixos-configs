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
  config = lib.mkIf (cfg.enable && cfg.withDockerRootless) {
    # This has some limitations but for my limited use-case, this is fine.
    # I can build and run most basic docker containers.
    # More info: https://docs.docker.com/engine/security/rootless/
    #
    # Please note that for rootless docker, the `docker` group doesn't exist and
    # has no effect.
    virtualisation.docker.rootless = {
      enable = true;
      # Sets SOCKER_HOST variable to the rootless Docker instance for normal
      # users by default.
      setSocketVariable = true;
    };
  };
}
