{
  config,
  lib,
  pkgs,
  ...
}@inputs:

let
  cfg = config.phip1611.common.user-env;
  pkgsUnstable = import inputs.nixpkgs-unstable {
    system = pkgs.system;
  };
in
{
  config = lib.mkIf cfg.enable {
    # Adds zsh to PATH and to /etc/shells and link /share/zsh for completions.
    programs.zsh.enable = true;

    home-manager.users."${cfg.username}" = {
      home.sessionVariables = {
        # Hide "user@host" in ZSH's agnoster-theme => shorter prompt
        DEFAULT_USER = cfg.username;
      };

      programs.zsh = {
        enable = true;
        package = pkgsUnstable.zsh;

        # TODO wait for https://github.com/nix-community/home-manager/pull/7333
        initContent = ''
          setopt INC_APPEND_HISTORY
        '';

        # Context:
        # - https://www.soberkoder.com/better-zsh-history/
        # - https://zsh.sourceforge.io/Doc/Release/Options.html
        # - https://zsh.sourceforge.io/Doc/Release/Parameters.html
        #
        # Home Manager Options:
        # <https://nix-community.github.io/home-manager/options.xhtml>
        history =
          let
            # Default is 10000.
            saveLines = 200000; # This results in roughly 1-6 MiB memory usage.
          in
          {
            # INC_APPEND_HISTORY
            # Append new commands immediately to the hist file.
            # TODO wait for https://github.com/nix-community/home-manager/pull/7333
            # appendInc = true;
            # EXTENDED_HISTORY
            # Save timestamp into the history file.
            extended = true;
            # HIST_IGNORE_DUPS
            # Don't push commands to the history if they are a duplicate of the
            # previous command.
            ignoreDups = true;
            # HIST_IGNORE_ALL_DUPS
            # Don't remove old duplicates (not previous command) from history.
            ignoreAllDups = false;
            # HIST_IGNORE_SPACE
            # Do not enter command lines into the history list if the first
            # character is a space.
            ignoreSpace = true;
            # SAVEHIST
            # Number of history lines to save on disk.
            save = saveLines;
            # HISTSIZE
            # Number of history lines to load into memory.
            size = saveLines;
            # SHARE_HISTORY
            # I'm using the mutually exclusive alternative INC_APPEND_HISTORY.
            share = false;
          };

        oh-my-zsh = {
          enable = true;
          theme = "agnoster";
          plugins = [
            "colored-man-pages"
            "docker"
            "docker-compose"
            "httpie"
            "git"
            "mvn"
            "ng"
            "urltools"
          ];
        };

        # With zplug, I manage external plugins that are not part of the
        # oh-my-zsh framework. They are installed automatically.
        zplug = {
          enable = true;
          plugins = [
            { name = "zsh-users/zsh-autosuggestions"; }
            { name = "zsh-users/zsh-syntax-highlighting"; }
            # use zsh in nix-shell
            { name = "chisui/zsh-nix-shell"; }
            # completions for nix attributes
            { name = "spwhitt/nix-zsh-completions"; }
          ];
        };
      };
    };
  };
}
