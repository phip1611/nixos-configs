# Overlays module

Combines all overlay NixOS modules from [`/common/nix`](/common/nix) and
enables them.

Further, it adds `pkgs.pkgsUnstable`, which is the `nixpkgs-unstable` flake
input (from `specialArgs`). All modules use this single instance instead of
importing nixpkgs-unstable themselves.
