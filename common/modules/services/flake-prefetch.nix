# Defines a systemd user service to prefetch Nix flake inputs from remote.
#
# The idea is to save me from unnecessary wait time when I frequently update
# my NixOS systems or fetch the latest upstream changes from this repository.
#
# As I use store optimization (hard linking) and garbage collection, the effects
# onto the Nix store should be negligible.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.phip1611.services.flake-prefetch;
in
{
  options.phip1611.services.flake-prefetch = {
    enable = lib.mkEnableOption "Enable Nix flake-prefetch user service";
    devShells = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of Nix dev shells to prefetch";
      default = [
        "github:phip1611/nixos-configs#default"
      ];
      example = [
        "github:phip1611/nixos-configs#default"
      ];
    };
    flakes = lib.mkOption {
      type = lib.types.listOf lib.types.singleLineStr;
      description = "Nix flake URLs to prefetch";
      default = [
        "github:NixOS/nixpkgs?ref=nixos-${config.system.nixos.release}"
        "github:NixOS/nixpkgs?ref=nixpkgs-unstable"
        "github:nix-community/home-manager?ref=release-${config.system.nixos.release}"
        "github:phip1611/nixos-configs"
      ];
      example = [
        "github:NixOS/nixpkgs?ref=nixos-${config.system.nixos.release}"
        "github:NixOS/nixpkgs?ref=nixpkgs-unstable"
        "github:nix-community/home-manager?ref=release-${config.system.nixos.release}"
        "github:phip1611/nixos-configs"
      ];
    };
    intervalMinutes = lib.mkOption {
      type = lib.types.int;
      description = "Interval in minutes for the service to run";
      # 4 times per hour
      default = 15;
      example = 15;
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.nix.enable;
        message = "Nix must be enabled on that machine";
      }
    ];
    systemd.user.services.flake-prefetch = {
      enable = true;
      description = "Nix flake-prefetch user service";
      environment = {
        DEV_SHELLS = lib.concatStringsSep " " cfg.devShells;
        FLAKES = lib.concatStringsSep " " cfg.flakes;
      };
      # Additional packages to standard path
      path = [
        config.nix.package
        pkgs.bash
      ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = ./flake-prefetch.sh;
      };
    };
    systemd.user.timers.flake-prefetch = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5m";
        OnUnitActiveSec = "${toString cfg.intervalMinutes}m";
        Unit = "flake-prefetch.service";
      };
    };
  };
}
