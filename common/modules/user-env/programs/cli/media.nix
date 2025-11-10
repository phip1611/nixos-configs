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
