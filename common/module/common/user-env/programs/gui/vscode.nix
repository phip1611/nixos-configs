# Sets the configuration for allacritty.

{ config, lib, pkgs, nixpkgs-unstable, ... }:

let
  cfg = config.phip1611.common.user-env;
  username = config.phip1611.username;
  pkgsUnstable = import nixpkgs-unstable {
    system = pkgs.system;
    config = {
      allowUnfree = true;
    };
  };
  vscode = pkgsUnstable.vscode;
in
{
  config = lib.mkIf (cfg.enable && cfg.withGui) {

    fonts.packages = with pkgs; [
      source-code-pro
    ];

    home-manager.users."${username}" = {
      programs.vscode = {
        enable = true;
        package = vscode;
        extensions = with pkgs.vscode-extensions; [
          bbenoist.nix
          tamasfe.even-better-toml
          editorconfig.editorconfig
          rust-lang.rust-analyzer
          github.vscode-github-actions
        ];
      };
    };

    # Not sure why, but if home-manager alone puts this package into PATH,
    # this package doesn't properly appear in the GNOME dock.
    users.users.${username}.packages = [
      vscode
    ];
  };
}
