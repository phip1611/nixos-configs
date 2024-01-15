{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.system;
in
{
  imports = [
    ./docker.nix
    ./documentation.nix
    ./firmware.nix
    ./latest-linux.nix
    ./nix-cfg.nix
    ./nix-ld.nix
    ./nix-path-from-flake.nix
    ./sudo.nix
  ];

  options = {
    phip1611.common.system = {
      enable = lib.mkEnableOption "Enable all system sub-modules at once";
    };
  };

  config = lib.mkIf cfg.enable {
    phip1611.common.system.docker.rootless.enable = lib.mkDefault true;
    phip1611.common.system.documentation.enable = lib.mkDefault true;
    phip1611.common.system.firmware.enable = lib.mkDefault true;
    phip1611.common.system.latest-linux.enable = lib.mkDefault true;
    phip1611.common.system.nix-cfg.enable = lib.mkDefault true;
    phip1611.common.system.nix-ld.enable = lib.mkDefault true;
    phip1611.common.system.nix-path-from-flake.enable = lib.mkDefault true;
    phip1611.common.system.sudo.enable = lib.mkDefault true;
  };
}
