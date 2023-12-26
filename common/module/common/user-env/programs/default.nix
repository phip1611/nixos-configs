{ config, lib, pkgs, ... }:

{
  imports = [
    ./cli
    ./gui
    ./dev.nix
    ./media.nix
  ];
}
