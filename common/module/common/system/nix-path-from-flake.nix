# Ensures that the used nixpkgs and nixpkgs-unstable version are available
# from the NIX_PATH as well as the Nix flake registry.

# nixpkgs and nixpkgs-unstable refers to flake inputs.
{ config, lib, pkgs, nixpkgs, nixpkgs-unstable, ... }:

let
  cfg = config.phip1611.common.system.nix-path-from-flake;
in
{
  options = {
    phip1611.common.system.nix-path-from-flake = {
      enable = lib.mkEnableOption "Enable to set NIX_PATH and Nix registry to the active nixpkgs flake";
    };
  };

  config = lib.mkIf cfg.enable {
    nix = {
      # By default, no on a flake-based Nix system, no Nix channels are
      # configured. As having a NIX_PATH simplifies easy prototyping in a Nix
      # repl or a Nix shell, I like to use them.
      #
      # This is also required so that `$ nix-shell -p foo` works.
      #
      # Changes to these are only applied to the environment after a re-login
      # of the user session.
      nixPath = [
        "nixpkgs=${nixpkgs}"
        "nixpkgs-unstable=${nixpkgs-unstable}"
      ];

      # In a Nix repl, one can do ":lf nixpkgs" or ":lf nixpkgs-unstable" with
      # the properly pinned versions. This is an alternative to the NIX_PATH.
      registry.nixpkgs.flake = nixpkgs;
      registry.nixpkgs-unstable.flake = nixpkgs-unstable;
    };
  };
}
