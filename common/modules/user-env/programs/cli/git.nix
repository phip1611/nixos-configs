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
      programs.delta = {
        # Enable the git-delta pager.
        enable = true;
        enableGitIntegration = true;
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
      programs.git = {
        enable = true;
        package = pkgsUnstable.git;
        ignores = [
          ".direnv/"
          ".idea/"
          "*.iml"
          ".vscode/"
          "cmake-build-*/"
        ];
        settings = {
          alias = {
            hist = "log --graph --decorate --oneline";
            hist2 = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)'";
            list-remotes = "! git remote | xargs -I {} sh -c \"echo -n '{} - ' && git remote get-url {}\"";
            # Helper for sending patches to mailing lists.
            publish = "! ${lib.getExe pkgsUnstable.git-publish}";
          };
          core = {
            editor = "micro";
          };
          diff = {
            colorMoved = "default";
          };
          init = {
            defaultBranch = "main";
          };
          pull = {
            rebase = true;
          };
          user.name = cfg.git.username;
          user.email = cfg.git.email;
        };
        lfs.enable = true; # Enable "git lfs <cmd>"
      };
    };
  };
}
