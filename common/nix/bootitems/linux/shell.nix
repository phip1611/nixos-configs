# Development shell for Linux. Focused to build the minimal kernel
# configuration.

{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  packages = with pkgs; [
    binutils
    bc
    bison
    elfutils
    flex
    gcc
    gnumake
    ncurses
    ncurses.dev
    openssl
    pahole
    pkg-config
    python3
    zlib
  ];

  # Disable all automatically applied hardening flags. The Linux kernel will
  # take care of itself.
  NIX_HARDENING_ENABLE = "";
}
