{ callPackage }:

{
  nix-shell-init = callPackage ./nix-shell-init.nix { };
  run-efi = callPackage ./run-efi.nix { };
  qemu-uefi = callPackage ./qemu-uefi.nix { };
}
