# libutil

Collection of utility functions for `nix`, `nixpkgs`, and `NixOS` that I
regularly, need, or find beneficial for other reasons.

## Prototyping in a REPL

For quick prototyping, you can just open `$ nix repl --file repl.nix`.

## Documentation

This library bundles some utility functions, such as

- `libutil.ansi.{color, style, reset, stylize, stylizeError, stylizeWarn}`
- `libutil.builders.{flattenDrv, unflattenDrv}`
- `libutil.trace.{pretty, prettyVal, prettyWithPrefix, prettyValWithPrefix}`
- `libutil.images.x86.{createBootableMultibootIso, createBootableMultibootEfi}`
- `libutil.writers.writeZxScriptBin`

## Overlay and NixOS Module

The overlay provided in `overlay.nix` is strictly additive and does not replace
anything. All functionality is added to the `pkgs.phip1611` attribute.
Additionally, you can add the overlay easily to your NixOS configuration by
importing the `overlay-module.nix` file.
