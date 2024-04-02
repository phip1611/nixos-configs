{ config, lib, pkgs, ... }:

let
  username = config.phip1611.username;
  cfg = config.phip1611.common.user-env;
in
{
  config = lib.mkIf cfg.enable {
    # Adds zsh to PATH and to /etc/shells and link /share/zsh for completions.
    programs.zsh.enable = true;

    home-manager.users."${username}" = {
      home.sessionVariables = {
        # Hide "user@host" in ZSH's agnoster-theme => shorter prompt
        DEFAULT_USER = username;
      };

      programs.zsh = {
        enable = true;

        # Context:
        # - https://www.soberkoder.com/better-zsh-history/
        # - https://zsh.sourceforge.io/Doc/Release/Options.html
        history =
          let
            # Default is 10000.
            saveLines = 200000; # This results in roughly 1-6 MiB memory usage.
          in
          {
            # Save timestamp into the history file.
            extended = true;
            # If a new command line being added to the history list duplicates
            # an older one, the older command is removed from the list (even if
            # it is not the previous event).
            # TODO this is on home-manager master but not on release-23.05.
            #  ADD ONCE it is stable.
            # ignoreAllDups = true;
            ignoreDups = true; # TODO Reevaluate once the option above is used.
            # Do not enter command lines into the history list if the first
            # character is a space.
            ignoreSpace = true;
            # Number of history lines to save.
            save = saveLines;
            # Number of history lines to load into memory.
            size = saveLines;
            # Share command history between zsh sessions. This also adds new
            # commands to the history as they are typed. Hence, this is more
            # powerful than INC_APPEND_HISTORY.
            share = true;
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
            "ripgrep"
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
