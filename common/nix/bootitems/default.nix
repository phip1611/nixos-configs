# Bundles and exports all bootitems.

{
  pkgs ? builtins.trace "WARN: Using nixpkgs from NIX_PATH" (import <nixpkgs> { }),
  libutil ? import ../libutil { inherit pkgs; },
  inputs,
}:

{
  linux = import ./linux { inherit libutil inputs pkgs; };
  tinytoykernel = pkgs.callPackage ./tinytoykernel { };
}
