{ config, lib, pkgs, ... }:

{
  imports = [
    ./nginx.nix
  ];

  config = {
    phip1611 = {
      username = "phip1611";
      common = {
        enable = true;
        user.env.excludeGui = true;
        user.env.git.username = "Philipp Schuster";
        user.env.git.email = "phip1611@gmail.com";
        user.pkgs.dev.enable = false;
        user.pkgs.fonts.enable = false;
        user.pkgs.gui.enable = false;
        user.pkgs.media.enable = false;
        user.pkgs.gnome-exts.enable = false;
        system.docker.rootless.enable = false;
      };
    };
  };
}
