{ pkgs, lib, config, options, ... }:

let
  cfg = config.phip1611.common.user.pkgs.custom;
  username = config.phip1611.username;
in
{
  imports = [
  ];

  options = {
    phip1611.common.user.pkgs.custom.enable = lib.mkEnableOption "Enable custom pkgs (convenient shell scripts, not in nixpkgs)";
  };

  config = lib.mkIf cfg.enable
    {
      users.users."${username}".packages = with pkgs; [
        # TODO add from libutil overlay
      ];
    };
}
