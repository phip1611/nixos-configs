{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.user-env;
   pkgsUnstable = import inputs.nixpkgs-unstable {
    system = pkgs.system;
  };
in
{
  config = lib.mkIf (cfg.enable && cfg.withGui) {
    programs.localsend.enable = true;
    programs.localsend.openFirewall = true;
    programs.localsend.package = pkgsUnstable.localsend;
  };
}
