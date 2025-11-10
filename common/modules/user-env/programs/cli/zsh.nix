{
  config,
  lib,
  pkgs,
  ...
}@inputs:

let
  cfg = config.phip1611.common.user-env;
  pkgsUnstable = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
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
        # Preferred over the explicit NixOS options:
        # https://github.com/nix-community/home-manager/pull/7333#issuecomment-3225914278
        #
        # Context:
        # - https://www.soberkoder.com/better-zsh-history/
        # - https://zsh.sourceforge.io/Doc/Release/Options.html
        # - https://zsh.sourceforge.io/Doc/Release/Parameters.html
        setOptions = lib.mapAttrsToList (name: enabled: if enabled then name else "NO_${name}") {
          APPEND_HISTORY = false;
          EXTENDED_HISTORY = true;
          HIST_EXPIRE_DUPS_FIRST = false;
          HIST_FCNTL_LOCK = true;
          HIST_FIND_NO_DUPS = false;
          HIST_IGNORE_ALL_DUPS = false;
          HIST_IGNORE_DUPS = true;
          HIST_IGNORE_SPACE = true;
          HIST_SAVE_NO_DUPS = false;
          INC_APPEND_HISTORY = true;
          # I prefer "INC_APPEND_HISTORY" over this, as I frequently work
          # with multiple terminals simultaneously that should keep their own
          # history as long as they are running.
          SHARE_HISTORY = false;
        };

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

            # SAVEHIST
            # Number of history lines to save on disk.
            save = saveLines;
            # HISTSIZE
            # Number of history lines to load into memory.
            size = saveLines;
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
