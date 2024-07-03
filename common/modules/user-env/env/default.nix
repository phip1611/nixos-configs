# This module enables typical environment settings (like default shell, prompt,
# dotfiles) and corresponding home-manager settings for the given user. This is
# intended as a big "all-in-one" module with no further enable sub-options.

{ config, lib, pkgs, ... }:

let
  stateVersion = config.system.stateVersion;
  cfg = config.phip1611.common.user-env;
in
{
  imports = [
    ./cargo.nix
    ./direnv.nix
  ];

  # Set some aliases and environment variables, plus other misc stuff.
  config = lib.mkIf cfg.enable {
    # ZSH as default shell for my user.
    users.users."${cfg.username}" = {
      shell = pkgs.zsh;
    };

    # https://nix-community.github.io/home-manager/nixos-options.html
    home-manager.useGlobalPkgs = true;
    # If this is true, GUI apps that are added by the programs.*.enable options
    # (such as Alacritty) are only accessible from the PATH but not from the
    # desktop environment anymore.
    home-manager.useUserPackages = false;

    home-manager.users."${cfg.username}" = {
      home.stateVersion = stateVersion;
      home.shellAliases = rec {
        eza = "eza -lagh -F --time-style=long-iso -o";
        # eza used to be exa.
        exa = eza;
      };

      home.sessionVariables = {
        # With zsh, the location where the definitions of the global NixOS option
        # "environment.variables.*" are placed is not taken into account.
        # (This is a bug, I guess?). Hence, I add these definitions in
        # home-manager, so they are actually sourced.
        #
        # I never came across a case where these variables are needed, however,
        # better be safe so that I can always use my favorite terminal editor in
        # my CLI utilities.
        EDITOR = "${pkgs.micro}/bin/micro";
        VISUAL = "${pkgs.micro}/bin/micro";

        # Configuration for LESS pager.
        LESS = "-R --mouse --wheel-lines=3 ";
      };
    };
  };
}
