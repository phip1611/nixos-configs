{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.user-env;
  username = config.phip1611.username;
  python3Toolchain = import ./python3-toolchain.nix { inherit pkgs; };
in
{
  config = lib.mkIf cfg.enable (lib.mkMerge [
    (
      lib.mkIf cfg.withDevJava {
        users.users."${username}".packages = (
          with pkgs; [
            jdk
            maven # TODO, JDK might be not needed, as the maven derivation
            # already comes with a JDK.
          ]
        );
      }
    )
    (
      lib.mkIf cfg.withDevJavascript {
        users.users."${username}".packages = (
          with pkgs; [
            nodejs
            yarn
          ]
        );
      }
    )
    (
      lib.mkIf cfg.withDevNix {
        users.users."${username}".packages = (
          with pkgs; [
            deadnix
            niv
            nixpkgs-fmt
            nixos-option
            # already there by default, here only for completeness
            nixos-rebuild
          ]
        );
      }
    )
    (
      lib.mkIf cfg.withDevCAndRust {
        users.users."${username}".packages = (
          with pkgs; [
            gcc
            # already there automatically; here only for completeness
            binutils
            clang-tools # clang-format
            cmake
            cmake-format
            gdb
            gnumake
            ninja
            valgrind
          ]
        );
      }
    )
    (
      lib.mkIf cfg.withDevCAndRust {
        users.users."${username}".packages = (
          with pkgs; [
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
      }
    )
    # A legacy env for development. For example, helpful to compile Linux.
    (
      lib.mkIf cfg.withDevCAndRust {
        users.users."${username}".packages = [
          (pkgs.buildFHSUserEnv {
            name = "legacy-env";
            targetPkgs = pkgs: with pkgs; [
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
              global
              gmp
              gmp.dev
              gnumake
              libmpc
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
      }
    )
  ]);
}
