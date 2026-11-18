{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.phip1611.common.user-env;
  inherit (pkgs) pkgsUnstable;
in
{
  config = lib.mkIf (cfg.enable && cfg.withMedia) {
    users.users."${cfg.username}".packages = (
      with pkgsUnstable;
      [
        exiftool
        ffmpeg
        jhead # `jhead -ft *` is very cool to view EFIF data!
        imagemagick
        libwebp # webp encoder
      ]
    );
  };
}
