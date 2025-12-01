# This module is a collection of custom systemd services that may be useful.
# User services may only exist after a relogin or restart. See
# https://discourse.nixos.org/t/nixos-22-11-systemd-user-services-dont-start-automatically-but-global-ones-do/24809

{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./ddns-update.nix
    ./flake-prefetch.nix
    ./zsh-history-backup.nix
  ];
}
