# On all my flake-based NixOS systems I remove all global Nix channels.
# However, for convenience (Nix repl, Nix shell, or simply prototyping) it is
# very convenient to have the pinned nixpkgs version in NIX_PATH and the flake
# registry (`$ nix-shell -p foo` or `pkgs = import <nixpkgs> {}` work).
#
# Changes to these are only applied to the environment after a re-login
# of the user session.

# Some inputs refers to flake inputs.
{
  config,
  lib,
  pkgs,
  ...
}@inputs:

let
  cfg = config.phip1611.common.system;
in
{
  config = lib.mkIf cfg.enable {
    # Deactivate the upstream functionally. I use my own variant of setting
    # NIX_PATH and the Flake registry for nixpkgs as well as nixpkgs-unstable.
    nixpkgs.flake.setNixPath = false;
    nixpkgs.flake.setFlakeRegistry = false;

    nix = {
      nixPath = [
        "nixpkgs=${inputs.nixpkgs}"
        "nixpkgs-unstable=${inputs.nixpkgs-unstable}"
      ];

      # Pinning some Nix flake registry to the versions the system is build
      # with and adding additional entries to point to upstream versions
      # (non-pinned).
      #
      # In a Nix repl, one can do ":lf nixpkgs" or ":lf nixpkgs-unstable" with
      # the properly pinned versions. This is an alternative to the NIX_PATH.
      # You can use `:lf nixpkgs-unstable-upstream` to access the latest
      # source from GitHub.
      registry = {
        home-manager.flake = inputs.home-manager;
        nixpkgs.flake = inputs.nixpkgs;
        nixpkgs-unstable.flake = inputs.nixpkgs-unstable;
        nixpkgs-unstable-upstream.to = builtins.parseFlakeRef "github:NixOS/nixpkgs?ref=nixpkgs-unstable";
        # Workaround as using `../..`, i.e., a Nix store path, doesn't work.
        phip1611.flake =
          if inputs ? phip1611 then
            inputs.phip1611
          else if inputs ? phip1611-common then
            inputs.phip1611-common
          # inputs.self is another flake when this module is consumed.
          else
            inputs.self;
        phip1611-upstream.to = builtins.parseFlakeRef "github:phip1611/nixos-configs";
      };
    };
  };
}
