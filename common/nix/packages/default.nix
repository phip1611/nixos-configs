{ pkgs }:

{
  ddns-update = pkgs.callPackage ./ddns-update { };
  # TODO remove once https://github.com/NixOS/nixpkgs/pull/301260 is merged
  extract-vmlinux = pkgs.callPackage ./extract-vmlinux { };
  keep-directory-diff = pkgs.callPackage ./keep-directory-diff { };
  nix-shell-init = pkgs.callPackage ./nix-shell-init { };
  normalize-file-permissions = pkgs.callPackage ./normalize-file-permissions { };
  run-efi = pkgs.callPackage ./run-efi { };
  qemu-uefi = pkgs.callPackage ./qemu-uefi { };
}
