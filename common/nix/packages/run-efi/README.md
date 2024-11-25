# `run-efi`

# Usage / Examples

Debug how the UEFI shell behaves when it executes a `startup.nsh` file: \
`nix run github:phip1611/nixos-configs#run-efi -- $(nix-build '<nixpkgs>' -A edk2-uefi-shell)/shell.efi ./startup.nsh`
