# Bundles and exports all modules of the "libutil" Nix library.

{ pkgs }:

{
  kernels = {
    tinytoykernel = pkgs.callPackage ./tinytoykernel { };
  };
  initrds = { };
}
