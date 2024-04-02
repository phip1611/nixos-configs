{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.user-env;
in
{
  options.phip1611.common.user-env = {
    git = {
      email = lib.mkOption {
        type = lib.types.str;
        description = "Default user email for git commits";
        example = "phip1611@gmail.com";
      };
      username = lib.mkOption {
        type = lib.types.str;
        description = "Default user name for git";
        example = "Philipp Schuster";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    home-manager.users."${cfg.username}" = {
      programs.git = {
        enable = true;
        userName = cfg.git.username;
        userEmail = cfg.git.email;
        aliases = {
          hist = "log --graph --decorate --oneline";
          hist2 = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)'";
          hist2all = "hist2 --all";
          list-remotes = "! git remote | xargs -I {} sh -c \"echo -n '{} - ' && git remote get-url {}\"";
        };
        ignores = [
          ".direnv/"
          ".idea/"
          "*.iml"
          ".vscode/"
          "cmake-build-*/"
        ];
        extraConfig = {
          core = {
            editor = "${pkgs.micro}/bin/micro";
          };
          pull = {
            rebase = true;
          };
          diff = {
            colorMoved = "default";
          };
          init = {
            defaultBranch = "main";
          };
        };
        # Enable the git-delta pager.
        delta = {
          enable = true;
          options = {
            features = "side-by-side line-numbers decorations";
            whitespace-error-style = "22 reverse";
            paging = "always";
            decorations = {
              commit-decoration-style = "bold yellow box ul";
              file-style = "bold yellow ul";
              file-decoration-style = "none";
            };
          };
        };
        lfs.enable = true; # Enable "git lfs <cmd>"
      };
    };
  };
}
