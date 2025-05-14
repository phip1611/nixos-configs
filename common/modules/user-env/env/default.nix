# This module enables typical environment settings (like default shell, prompt,
# dotfiles) and corresponding home-manager settings for the given user. This is
# intended as a big "all-in-one" module with no further enable sub-options.

{
  config,
  lib,
  pkgs,
  ...
}:

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
    users.users."${cfg.username}" =
      let
        systemCfg = config.phip1611.common.system;
      in
      {
        # ZSH as default shell for my user.
        shell = pkgs.zsh;
        # Add user to docker group.
        extraGroups = lib.optional (systemCfg.enable && systemCfg.withDocker) "docker";
      };

    # https://nix-community.github.io/home-manager/options.xhtml
    home-manager.useGlobalPkgs = true;
    # If this is true, GUI apps that are added by the programs.*.enable options
    # (such as Alacritty) are only accessible from the PATH but not from the
    # desktop environment anymore.
    home-manager.useUserPackages = false;

    home-manager.users."${cfg.username}" = {
      home.stateVersion = stateVersion;
      home.shellAliases = rec {
        clip = "xclip -sel clip";
        eza = "eza -lagh -F --time-style=long-iso -o";
        # eza used to be exa.
        exa = eza;
      };

      home.sessionVariables = {
        # Configuration for LESS pager.
        LESS = "-R --mouse --wheel-lines=3 ";
      };
    };
  };
}
