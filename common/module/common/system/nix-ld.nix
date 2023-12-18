# nix-ld setup: https://github.com/Mic92/nix-ld
# Run unpatched dynamic binaries on NixOS
#
# Note: Since NixOS 23.05 the setup got quite convenient and the official README
#       on GitHub is outdated at the moment.
#
# This is for example useful to enable a dynamic binary used by the Rust plugin
# of Jetbrains IDE. Without it, CLion tells warnings that say
# "could not learn about target-specific information from rustc".

{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.system.nix-ld;
in
{
  options = {
    phip1611.common.system.nix-ld.enable = lib.mkEnableOption "Enable nix-ld to run unpatched dynamic binaries on NixOS";
  };

  config = lib.mkIf cfg.enable {
    # When unpatched dynamically linked programs are executed, they fail with
    # file not found. Usually, the file "/lib64/ld-linux-x86-x64.so.2" is not
    # found. This NixOS package adds a compatibility layer for that case.
    #
    # if true: Sets the NIX_LD and NIX_LD_LIBRARY_PATH env variables and adds
    # "programs.nix-ld.libraries" to environment.systemPackages.
    #
    # Caution: For reproducibility and less global state, it would be much
    # better to set the env var NIX_LD_LIBRARY_PATH only for specific bins, such
    # as through a nix shell.
    programs.nix-ld.enable = true;
  };
}
