# Common NixOS Module

This directory contains my common NixOS module (`./default.nix`). It consists of
further submodules that provide various configuration options that can be
activated or deactivated on a fine-grained level. It is intended to include
the top-level module only. For fine-tuning, you can use the provided options.

In this directory, each `default.nix` usually is a NixOS module.

There are the following major submodules available:
- [common](common/README.md): typical environment setup of a system and user-specific things,
  such as the shell and CLI tools
- [network-boot](network-boot/README.md): Configurations for a network boot setup
- [services](services/README.md): systemd services

All options are prefixed with `phip1611`. You can view a list of all oft those
with their default option by running:

```shell
$ nix run .\#listNixosOptions
```

## Inputs

The module needs the flake inputs `nixpkgs` and `nixpkgs-unstable` as
`specialArgs` (see `nixpkgs.lib.nixosSystem `) to set the `NIX_PATH` and the
`nix registry` properly. Furthermore,
[Home manager](https://github.com/nix-community/home-manager) must be globally
available for the `common.user.env` module. This module doesn't import
home-manager itself as this doesn't work conditionally with Nix via a NixOS
configuration option.

## Additional Notes

Some NixOS options require a restart of the system to have a fully applied NixOS
config, such as systemd user services.
