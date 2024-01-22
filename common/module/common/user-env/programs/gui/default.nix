{ config, lib, pkgs, nixpkgs-unstable, ... }:

let
  cfg = config.phip1611.common.user-env;
  pkgsUnstable = import nixpkgs-unstable {
    system = pkgs.system;
    config = {
      allowUnfree = true;
    };
  };
  username = config.phip1611.username;
in
{
  imports = [
    ./alacritty.nix
    ./teamviewer.nix
    ./vscode.nix
  ];
  config = lib.mkIf (cfg.enable && cfg.withGui) {
    # Teamviewer GUI doesn't work without the daemon.
    services.teamviewer.enable = true;

    users.users."${username}".packages = (
      with pkgs; [
        firefox
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
    );
  };
}
