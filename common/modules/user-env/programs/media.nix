{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.user-env;
in
{
  config = lib.mkIf (cfg.enable && cfg.withMedia) {
    users.users."${cfg.username}".packages = (
      with pkgs; [
        exiftool
        ffmpeg
        jhead # `jheda -ft *` is very cool!
        imagemagick
        libwebp # webp encoder
      ]
    );
  };
}
