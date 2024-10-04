{ config, lib, pkgs, ... }@inputs:

let
  cfg = config.phip1611.common.user-env;
  pkgsUnstable = import inputs.nixpkgs-unstable {
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
      with pkgsUnstable; [
        _1password-gui
        drawio
        gimp
        (google-chrome.override {
          # Some of these flags correspond to chrome://flags
          commandLineArgs = [
            # Correct fractional scaling.
            "--ozone-platform-hint=wayland"
            # Hardware video encoding on Chrome on Linux.
            # See chrome://gpu to verify.
            "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder"
          ];
        })
        gparted
        signal-desktop
        spotify
        teamviewer
        telegram-desktop
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
        with pkgsUnstable; [
          audacity
        ]
      )
    );
  };
}
