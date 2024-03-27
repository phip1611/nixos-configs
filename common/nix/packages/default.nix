{ pkgs }:

{
  ddns-update = pkgs.callPackage ./ddns-update { };
  nix-shell-init = pkgs.callPackage ./nix-shell-init { };
  normalize-file-permissions = pkgs.callPackage ./normalize-file-permissions { };
  run-efi = pkgs.callPackage ./run-efi { };
  qemu-uefi = pkgs.callPackage ./qemu-uefi { };
}
