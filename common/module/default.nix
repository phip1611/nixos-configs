# Main entry module into the my common NixOS module. Users are supposed to
# include this. All depending functionality can be activated or deactivated,
# depending on the defaults of the `*.enable` attributes.

{ config, lib, pkgs, ... }:

{
  imports = [
    ./common
    ./network-boot
    ./services
    ../libutil/overlay.module.nix
    ../pkgs/overlay.module.nix
  ];

  options.phip1611 = {
    # There was an attempt to make this a "users" array, but I don't think it is
    # worth it: https://github.com/phip1611/dotfiles/pull/38
    username = lib.mkOption {
      type = lib.types.str;
      description = "User for that all enabled configurations apply";
      default = "phip1611";
    };
  };

  config = {
    phip1611 = {
      # By default, the overlays are activated.
      libutil-overlay.enable = true;
      pkgs-overlay.enable = true;
    };
  };
}
