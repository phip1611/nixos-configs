# Bundles and exports all bootitems.

{
  pkgs ? builtins.trace "WARN: Using nixpkgs from NIX_PATH" (import <nixpkgs> { }),
  libutil ? import ../libutil { inherit pkgs; },
  # Only available when built from flake, not for local `nix-build` prototyping
  memtouch ? null,
}:

{
  linux = import ./linux { inherit libutil memtouch pkgs; };
  tinytoykernel = pkgs.callPackage ./tinytoykernel { };
}
