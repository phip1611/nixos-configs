# Bundles and exports all bootitems.

{
  pkgs ? builtins.trace "WARN: Using nixpkgs from NIX_PATH" (import <nixpkgs> { }),
  libutil ? import ../libutil { inherit pkgs; },
  memtouch,
}:

{
  linux = import ./linux { inherit libutil memtouch pkgs; };
  tinytoykernel = pkgs.callPackage ./tinytoykernel { };
}
