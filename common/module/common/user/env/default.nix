# This module enables typical environment settings (like default shell, prompt)
# and home-manager for the given user. This is intended as a big "all-in-one"
# module with no further sub-enable-options.

{ pkgs, lib, config, options, ... }:

let
  username = config.phip1611.username;
  stateVersion = config.system.stateVersion;
  cfg = config.phip1611.common.user.env;
in
{
  imports = [
    ./alacritty.nix
    ./cargo.nix
    ./direnv.nix
    ./git.nix
    ./tmux.nix
    ./vscode.nix
    ./zsh.nix
  ];

  options = {
    phip1611.common.user.env = {
      enable = lib.mkEnableOption "Enable all user-environmental options (shell, homemanager, dotfiles, ...)";
      # Useful as those options are not needed in CLI-only environments. Most/
      # all of those settings will bring them into the path and occupy storage.
      excludeGui = lib.mkEnableOption "Disable configurations for GUI-based utilities (alacritty, vs code, ...)";
    };
  };

  # Set some aliases and environment variables, plus other misc stuff.
  config = lib.mkIf cfg.enable {
    # https://nix-community.github.io/home-manager/nixos-options.html
    home-manager.useGlobalPkgs = true;
    # If this is true, GUI apps that are added by the programs.*.enable options
    # (such as Alacritty) are only accessible from the PATH but not from the
    # desktop environment anymore.
    home-manager.useUserPackages = false;

    home-manager.users."${username}" = {
      home.stateVersion = stateVersion;
      home.shellAliases = {
        eza = "eza -lFagh --time-style=long-iso";
        exa = "eza -lFagh --time-style=long-iso";
      };

      # With zsh, the location where the definitions of the global NixOS option
      # "environment.variables.*" are placed is not taken into account.
      # (This is a bug, I guess?). Hence, I add these definitions in
      # home-manager, so they are actually sourced.
      #
      # I never came across a case where these variables are needed, however,
      # better be safe so that I can always use micro in my CLI utilities.
      home.sessionVariables = {
        EDITOR = "${pkgs.micro}/bin/micro";
        VISUAL = "${pkgs.micro}/bin/micro";
      };
    };
  };
}
