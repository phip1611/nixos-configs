# libutil

Collection of utility functions for `nix`, `nixpkgs`, and `NixOS` that I
regularly, need, or find beneficial for other reasons. Some of these functions
are independent of the scope of a NixOS and can be used separately.

## Prototyping

For quick prototyping, you can just do `$ nix repl --file repl.nix`.

## Documentation

This optional module adds a few utils as overlay to `pkgs`, such as
- `libutil.ansi.{color, style, reset, stylize, stylizeError, stylizeWarn}`
- `libutil.builders.{flattenDrv, unflattenDrv}`
- `libutil.trace.{pretty, prettyVal, prettyWithPrefix, prettyValWithPrefix}`
- `libutil.images.x86.{createBootableMultibootIso, createBootableMultibootEfi}`
- `libutil.customPkgs.{nix-shell-init, run-efi, qemu-uefi}`
- `libutil.writers.writeZxScriptBin`

## Overlay and NixOS Module

The overlay provided in `overlay.nix` is strictly additive and all functionality
is behind the `phip1611-util` attribute. Additionally, you can add the overlay
easily to your NixOS configuration by importing the `overlay-module.nix` file.
