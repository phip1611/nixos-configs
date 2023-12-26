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
in
{
  config = lib.mkIf (cfg.enable && cfg.withGui) {

    fonts.packages = with pkgs; [
      source-code-pro
    ];

    home-manager.users."${username}" = {
      programs.vscode = {
        enable = true;
        package = pkgsUnstable.vscode;
        extensions = with pkgs.vscode-extensions; [
          bbenoist.nix
          tamasfe.even-better-toml
          editorconfig.editorconfig
          rust-lang.rust-analyzer
          github.vscode-github-actions
        ];
      };
    };
  };
}
