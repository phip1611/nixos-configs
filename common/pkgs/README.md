# pkgs

Collection of additional packages that I like to use in Nix(OS) but that are not
worth upstreaming.

## Prototyping in a REPL

For quick prototyping, you can just open `$ nix repl --file repl.nix`.

## Documentation

This directory bundles some utility packages, such as

- `ddns-update`
- `nix-shell-init`
- `qemu-uefi`
- `run-efi`

## Overlay and NixOS Module

The overlay provided in `overlay.nix` is strictly additive and does not replace
anything. All functionality is added to the `pkgs.phip1611` attribute.
Additionally, you can add the overlay easily to your NixOS configuration by
importing the `overlay-module.nix` file.
