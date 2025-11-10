# Minimal yet useful and usable Python 3 toolchain. This is primarily required
# in the global scope so that CLion and other IDEs (that do not get their
# context easily from a nix-shell), can find Python properly.

{ pkgs }:

pkgs.python3.withPackages (
  ps: with ps; [
    pip
    setuptools
  ]
)
