{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.user.pkgs.media;
  username = config.phip1611.username;
in
{
  options = {
    phip1611.common.user.pkgs.media.enable = lib.mkEnableOption "Enable media packages (ffmpeg, imagemagick ,...)";
  };

  config = lib.mkIf cfg.enable {
    users.users."${username}".packages = with pkgs; [
      ffmpeg
      imagemagick
      libwebp # webp encoder
    ];
  };
}
