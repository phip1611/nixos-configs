{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.system;
in
{
  config = lib.mkIf cfg.enable {
    documentation.enable = true;
    documentation.dev.enable = true;
    documentation.doc.enable = false; # /share/doc (HTML resources, etc.)
    documentation.info.enable = false; # /share/info (content for info command)
    documentation.man.enable = true;
    documentation.nixos.enable = true;

    environment.systemPackages = (with pkgs; [
      man-pages # enables for example to type `$ man 2 open`
      man-pages-posix
    ]);
  };
}
