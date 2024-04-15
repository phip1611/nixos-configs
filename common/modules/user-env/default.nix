# This module affects all installed user packages and environmental settings,
# such as the used shell, dotfiles for git and tmux, environmental variables,
# and installed CLI tools and GUI applications.
#
# Generally speaking, this is a "all in" module. There are only switches for
# functionality that has a notable amount of impact in disk space or other
# properties, when this functionality is not mandatory on all my systems.

{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.user-env;
in
{
  imports = [
    ./env
    ./programs
    ./bootitems.nix
    ./fonts.nix
    ./nix.nix
    ./gnome-exts.nix
  ];

  options.phip1611.common.user-env = {
    enable = lib.mkEnableOption "Enable all user sub-modules at once";
    username = lib.mkOption {
      description = "User for that all enabled configurations apply";
      example = "phip1611";
    };
    withBootitems = lib.mkEnableOption "Place various ready-to-use bootitems in /etc/bootitems for OS development";
    withDevCAndRust = lib.mkEnableOption "Include a C++ and Rust toolchain and convenient helper tools for development";
    withDevJava = lib.mkEnableOption "Include a Java toolchain and convenient helper tools for development";
    withDevJavascript = lib.mkEnableOption "Include developer tools for JavaScript (Node, yarn, ...)";
    withDevNix = lib.mkEnableOption "Include developer tools for Nix (formatter, deadnix, ...)";
    # withGui also means "with desktop environment"
    withGui = lib.mkEnableOption "Include GUI-based applications";
    withMedia = lib.mkEnableOption "Include tools to enable media (images, videos, ...)";
    withPerf = lib.mkEnableOption "Include perf tooling for the current kernel";
    withPkgsJ4F = lib.mkEnableOption "Include just-for-fun packages (cowsay, lolcat, hollywood, ...)";
    withVmms = lib.mkEnableOption "Include VMMs (QEMU, Cloud Hypervisor)";
  };

  config = lib.mkIf cfg.enable {
    phip1611.common.user-env.withBootitems = lib.mkDefault true;
    phip1611.common.user-env.withDevCAndRust = lib.mkDefault true;
    phip1611.common.user-env.withDevJava = lib.mkDefault true;
    phip1611.common.user-env.withDevJavascript = lib.mkDefault true;
    phip1611.common.user-env.withDevNix = lib.mkDefault true;
    phip1611.common.user-env.withGui = lib.mkDefault true;
    phip1611.common.user-env.withMedia = lib.mkDefault true;
    phip1611.common.user-env.withPerf = lib.mkDefault true;
    phip1611.common.user-env.withPkgsJ4F = lib.mkDefault true;
    phip1611.common.user-env.withVmms = lib.mkDefault true;
  };
}
