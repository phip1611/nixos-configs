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
# TODO: Add dynamic configuration of plugins
# https://github.com/nix-community/home-manager/pull/3224
{
  config = lib.mkIf cfg.enable {
    home-manager.users."${cfg.username}" =
      # Module variables from home-manager, not NixOS.
      { config, lib, ... }:
      {
        # TODO somehow add the ".editorconfig" plugin:
        # https://github.com/10sr/editorconfig-micro

        programs.micro.enable = true;
        programs.micro.package = pkgsUnstable.micro;
        programs.micro.settings = {
          colorcolumn = 80;
          colorscheme = "material-tc";
          mkparents = true;
          rmtrailingws = true;
          savecursor = true;
          tabsize = 4;
          # Will still be overridden for Makefiles by the "ftoptions" plugin.
          tabstospaces = true;
        };
        # Taken from https://github.com/nix-community/home-manager/pull/3224
        # Remove once the upstream PR is ever merged.
        home.sessionVariables = {
          MICRO_TRUECOLOR = "1";
        };
      };
  };
}
