{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.user-env;

  # Something from `$ micro -plugin available`
  additionalMicroPlugins = [
    "editorconfig"
  ];
in
{
  config = lib.mkIf cfg.enable {
    home-manager.users."${cfg.username}" =
      # Module variables from home-manager, not NixOS.
      { config, lib, ... }: {
        # TODO somehow add the ".editorconfig" plugin:
        # https://github.com/10sr/editorconfig-micro
        programs.micro.enable = true;
        programs.micro.settings = {
          colorcolumn = 80;
          colorscheme = "material-tc";
          mkparents = true;
          rmtrailingws = true;
          savecursor = true;
          tabsize = 4;
          # Will still be overriden for Makefiles by the "ftoptions" plugin.
          tabstospaces = true;
        };
        # Taken from https://github.com/nix-community/home-manager/pull/3224
        # Remove once the upstream PR is ever merged.
        home.sessionVariables = {
          MICRO_TRUECOLOR = "1";
        };
        home.activation.micro = (lib.hm.dag.entryAfter [ "createXdgUserDirectories" "writeBoundary" ])
          (
            let
              mkInstall =
                pluginName: ''
                  if ! test -d ${config.xdg.configHome}/micro/plug/${
                    lib.escapeShellArg pluginName
                  }; then
                    (set -x
                      # TODO in home-manager 24.05, this should be refactored:
                      # https://github.com/nix-community/home-manager/blob/1c2acec99933f9835cc7ad47e35303de92d923a4/docs/release-notes/rl-2405.md?plain=1#L34
                      $DRY_RUN_CMD ${pkgs.micro}/bin/micro -plugin install ${
                        lib.escapeShellArg pluginName
                      }
                    )
                  fi
                '';
            in
            builtins.concatStringsSep "\n" (map mkInstall additionalMicroPlugins)
          );
      };
  };
}
