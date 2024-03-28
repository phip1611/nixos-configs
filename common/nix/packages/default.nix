{ pkgs }:

{
  ddns-update = pkgs.callPackage ./ddns-update { };
  extract-vmlinux = pkgs.callPackage ./extract-vmlinux { };
  nix-shell-init = pkgs.callPackage ./nix-shell-init { };
  normalize-file-permissions = pkgs.callPackage ./normalize-file-permissions { };
  run-efi = pkgs.callPackage ./run-efi { };
  qemu-uefi = pkgs.callPackage ./qemu-uefi { };
}
