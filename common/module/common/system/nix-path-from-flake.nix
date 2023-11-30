{ lib, config, options, nixpkgs, nixpkgs-unstable, ... }:

let
  cfg = config.phip1611.common.system.nix-path-from-flake;
in
{
  options = {
    phip1611.common.system.nix-path-from-flake.enable = lib.mkEnableOption "Enable to set NIX_PATH and Nix registry to the active nixpkgs flake";
  };

  config = lib.mkIf cfg.enable {
    nix = {
      # Set the nix channel to the one that comes from my NixOS configurations's
      # flake. I still sometimes use Nix channels for quick prototyping.
      #
      # This is also relevant so that `$ nix-shell -p foo` works.
      nixPath = [
        "nixpkgs=${nixpkgs}"
        "nixpkgs-unstable=${nixpkgs-unstable}"
      ];
      registry.nixpkgs.flake = nixpkgs;
    };
  };
}
