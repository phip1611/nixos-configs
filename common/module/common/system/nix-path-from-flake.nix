# Ensures that the used nixpkgs and nixpkgs-unstable version are available
# from the NIX_PATH as well as the Nix flake registry.

# nixpkgs and nixpkgs-unstable refers to flake inputs.
{ config, lib, pkgs, nixpkgs, nixpkgs-unstable, ... }:

let
  cfg = config.phip1611.common.system;
in
{
  config = lib.mkIf cfg.enable {
    nix = {
      # On all my flake-based NixOS systems I remove all Nix channels. However,
      # as having nixpkgs in NIX_PATH simplifies easy prototyping in a Nix
      # repl or a Nix shell, I like to configure NIX_PATH accordingly.
      #
      # Having nixpkgs in NIX_PATH is also required for `$ nix-shell -p foo`.
      #
      # Changes to these are only applied to the environment after a re-login
      # of the user session.
      nixPath = [
        "nixpkgs=${nixpkgs}"
        "nixpkgs-unstable=${nixpkgs-unstable}"
      ];

      # Pinning the Nix flake registry to the versions the system is build with.
      #
      # In a Nix repl, one can do ":lf nixpkgs" or ":lf nixpkgs-unstable" with
      # the properly pinned versions. This is an alternative to the NIX_PATH.
      registry = {
        nixpkgs.flake = nixpkgs;
        nixpkgs-unstable.flake = nixpkgs-unstable;
      };
    };
  };
}
