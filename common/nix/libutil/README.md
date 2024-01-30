# libutil

Collection of utility functions for `nix`, `nixpkgs`, and `NixOS` that I
regularly, need, or find beneficial for other reasons.

## Documentation

This library bundles some utility functions, such as

- `libutil.ansi.{color, style, reset, stylize, stylizeError, stylizeWarn}`
- `libutil.builders.{flattenDrv, unflattenDrv}`
- `libutil.trace.{pretty, prettyVal, prettyWithPrefix, prettyValWithPrefix}`
- `libutil.images.x86.{createBootableMultibootIso, createBootableMultibootEfi}`
- `libutil.writers.writeZxScriptBin`
