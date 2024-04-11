# I use the following priority to configure programs:
# 1.) `programs.*.enable` options from NixOS
# 2.) `programs.*.enable` options from home-manager
# 3.) directly adding pkgs to the PATH

{ config, lib, pkgs, ... }:

{
  imports = [
    ./cli
    ./gui
    ./dev.nix
    ./media.nix
  ];
}
