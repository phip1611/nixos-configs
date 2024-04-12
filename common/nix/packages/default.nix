{ pkgs }:

let
  src = ./.;
  callPackages = names:
    builtins.foldl'
      (acc: package:
        acc // {
          "${package}" = pkgs.callPackage "${src}/${package}" { };
        }
      )
      { }
      names;
in
callPackages
  [
    "colortest"
    "ddns-update"
    # TODO remove once https://github.com/NixOS/nixpkgs/pull/301260 is merged
    "extract-vmlinux"
    "keep-directory-diff"
    "link-to-copy"
    "nix-shell-init"
    "normalize-file-permissions"
    "run-efi"
    "qemu-uefi"
  ]
