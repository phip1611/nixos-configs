# Common NixOS Modules

This directory contains my common NixOS modules. Each consists of multiple
submodules but this is irrelevant for consuming them. By default, no module
does something to your system without the corresponding `enable` option
that must be set to true. For fine-tuning, you can use the provided options.

In this directory, each `default.nix` usually is a NixOS module.

There are the following major submodules available:
- [bootitems](bootitems/README.md): Place various ready-to-use bootitems (kernels, initrds) in /etc/bootitems for OS development
- [network-boot](network-boot/README.md): Configurations for a network boot setup
- [user-env](user-env/README.md): typical user-environment specific things,
  such as the shell and CLI tools
- [overlays](overlays/README.md): common overlays
- [services](services/README.md): common system services
- [system](system/README.md): typical global environment setup

All NixOS options are prefixed with `phip1611`. You can view a list of all oft
those with their default option by running:

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
