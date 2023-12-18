# Development-related dependencies.

{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.user.pkgs.dev;
  username = config.phip1611.username;
in
{
  options = {
    phip1611.common.user.pkgs.dev.enable = lib.mkEnableOption "Enable development-related pkgs (gcc, rustup, ...)";
  };

  config = lib.mkIf cfg.enable {
    users.users."${username}".packages = with pkgs; [
      # +++ Cargo utils +++
      cargo-deny
      cargo-expand
      cargo-license
      cargo-msrv
      cargo-nextest
      cargo-outdated
      cargo-release
      cargo-update
      cargo-watch

      # +++ dev tools+++
      deadnix
      gcc
      # already there automatically; here only for completeness
      binutils
      clang-tools # clang-format
      cmake
      cmake-format
      gdb
      gnumake
      grub2 # for grub-file etc.
      # for USB serial: "sudo minicom -D /dev/ttyUSB0"
      minicom
      ninja
      niv
      nodejs
      # Rustup can't auto-update itself but installed Rust toolchains.
      rustup
      valgrind
      yarn
      yamlfmt
      # Experience shows that this is not working in all cases as intended.
      # Instead, projects should open a nix-shell like this:
      # `$ nix-shell -p openssl pkg-config`
      # pkg-config
      qemu

      # Always use the matching perf for the current selected kernel.
      config.boot.kernelPackages.perf
    ];
  };
}
