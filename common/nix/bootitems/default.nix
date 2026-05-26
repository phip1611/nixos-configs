# Bundles and exports all bootitems.

{
  pkgs ? builtins.trace "WARN: Using nixpkgs from NIX_PATH" (import <nixpkgs> { }),
  libutil ? import ../libutil { inherit pkgs; },
}:

{
  linux = import ./linux { inherit libutil pkgs; };
  tinytoykernel = pkgs.callPackage ./tinytoykernel { };
}
