{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.user-env;
in
{
  config = lib.mkIf cfg.enable {
    home-manager.users."${cfg.username}" = {
      programs.direnv.enable = true;
      # A faster, persistent implementation of direnv's use_nix and use_flake,
      # to replace the built-in one from "direnv".
      # https://github.com/nix-community/nix-direnv
      programs.direnv.nix-direnv.enable = true;
    };
  };
}
