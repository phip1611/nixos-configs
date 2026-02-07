# CLI tools for development.
{
  config,
  lib,
  pkgs,
  ...
}@inputs:

let
  cfg = config.phip1611.common.user-env;
  pkgsUnstable = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
  };
  python3Toolchain = import ../_python3-toolchain.nix { pkgs = pkgsUnstable; };
in
{
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf cfg.withDevJava {
        users.users."${cfg.username}".packages = (
          with pkgsUnstable;
          [
            jdk
            maven
          ]
        );
      })
      (lib.mkIf cfg.withDevJavascript {
        users.users."${cfg.username}".packages = (
          with pkgsUnstable;
          [
            nodejs
            pnpm
            yarn
          ]
        );
      })
      (lib.mkIf cfg.withDevNix {
        users.users."${cfg.username}".packages = (
          with pkgsUnstable;
          [
            deadnix
            nixos-option
            nix-output-monitor
            # already there by default
            # nixos-rebuild
          ]
        );
      })
      (lib.mkIf cfg.withDevCAndRust {
        users.users."${cfg.username}".packages = (
          with pkgsUnstable;
          [
            # already there automatically; here only for completeness
            binutils
            clang-tools # clang-format
            cmake
            cmake-format
            gcc
            gdb
            git
            gh # GitHub CLI
            gitlab-timelogs
            gitui
            gnumake
            grub2 # for grub-file
            ninja
            perf
            valgrind
          ]
        );
      })
      (lib.mkIf cfg.withDevCAndRust {
        users.users."${cfg.username}".packages = (
          with pkgsUnstable;
          [
            cargo-careful
            cargo-deny
            cargo-expand
            cargo-license
            cargo-msrv
            cargo-nextest
            cargo-outdated
            cargo-release
            cargo-update
            cargo-watch

            # Rustup can't auto-update itself but manage installed Rust
            # toolchains.
            rustup
          ]
        );
      })
      (lib.mkIf cfg.withDevCAndRust {
        users.users."${cfg.username}".packages = [
          # A legacy env for development. For example, helpful to build Linux
          # out-of-tree modules right from the shell.
          (pkgs.buildFHSEnv {
            name = "legacy-env";
            targetPkgs =
              _pkgs: with pkgsUnstable; [
                acpica-tools
                bc
                binutils
                bison
                coreutils
                cpio
                curl
                elfutils.dev
                file
                flex
                gawk
                gcc
                git
                gmp
                gmp.dev
                gnumake
                libmpc
                linux.dev
                linux_latest.dev
                m4
                mpfr
                mpfr.dev
                ncurses.dev
                nettools
                openssl
                openssl.dev
                pahole
                patch
                perl
                python3Toolchain
                rsync
                unzip
                zlib
                zlib.dev
                zstd
              ];
          })
        ];
      })
    ]
  );
}
