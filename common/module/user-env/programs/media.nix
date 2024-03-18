{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.user-env;
  username = config.phip1611.username;
in
{
  config = lib.mkIf cfg.withMedia {
    users.users."${username}".packages = (
      with pkgs; [
        ffmpeg
        imagemagick
        libwebp # webp encoder
      ]
    );
  };
}
