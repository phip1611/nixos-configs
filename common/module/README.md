# Common NixOS Modules

This directory contains my common NixOS module (`./default.nix`). It consists of
further submodules that provide various configuration options that can be
activated or deactivated on a fine-grained level. It is intended to include
the top-level module only. For fine-tuning, you can use the provided options.

In this directory, each `default.nix` usually is a NixOS module.

There are the following major submodules available:
- [network-boot](network-boot/README.md): Configurations for a network boot setup
- [user-env](user-env/README.md): typical user-environment specific things,
  such as the shell and CLI tools
- [services](services/README.md): common system services
- [system](system/README.md): typical global environment setup

All options are prefixed with `phip1611`. You can view a list of all oft those
with their default option by running:

```shell
$ nix run .\#listNixosOptions
```

## Dependencies / Required Inputs

The module needs the flake inputs `nixpkgs` and `nixpkgs-unstable` as
`specialArgs` (see `nixpkgs.lib.nixosSystem `). Furthermore, some NixOS options
require the options from the
[Home manager](https://github.com/nix-community/home-manager) module to be
available. The common module doesn't import home-manager itself because
the module is standalone and dependencies should be managed in a flake.


## Overlays

The module automatically adds the relevant overlays from this repository to
`config.nixpkgs.overlays`.


## Additional Notes

Some NixOS options require a restart of the system to have a fully applied NixOS
config, such as systemd user services or changes to environment variaböes.
