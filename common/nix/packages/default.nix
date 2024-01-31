# Bundles and exports all sub modules of the "libutil" nix library.

{ pkgs
  # , libutil ? pkgs.phip1611.libutil
}:

{
  ddns-update = pkgs.callPackage ./ddns-update { };
  # TODO remove once upstream
  limine = pkgs.callPackage ./limine { };
  nix-shell-init = pkgs.callPackage ./nix-shell-init { };
  run-efi = pkgs.callPackage ./run-efi { };
  qemu-uefi = pkgs.callPackage ./qemu-uefi { };
}
