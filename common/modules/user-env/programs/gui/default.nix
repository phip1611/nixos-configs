{ config, lib, pkgs, nixpkgs-unstable, ... }:

let
  cfg = config.phip1611.common.user-env;
  pkgsUnstable = import nixpkgs-unstable {
    system = pkgs.system;
    config = {
      allowUnfree = true;
    };
  };
in
{
  imports = [
    ./alacritty.nix
    ./teamviewer.nix
    ./vscode.nix
  ];
  config = lib.mkIf (cfg.enable && cfg.withGui) {
    programs.firefox.enable = true;

    # Teamviewer GUI doesn't work without the daemon.
    services.teamviewer.enable = true;

    users.users."${cfg.username}".packages = (
      with pkgs; [
        gimp
        google-chrome
        gparted
        signal-desktop
        spotify
        teamviewer
        tdesktop # telegram desktop
        xournalpp
      ]
    ) ++ (
      lib.optionals cfg.withDevCAndRust (
        with pkgsUnstable; [
          jetbrains.clion
          jetbrains.rust-rover
        ]
      )
    ) ++ (
      lib.optionals cfg.withMedia (
        with pkgs; [
          audacity
        ]
      )
    );
  };
}
