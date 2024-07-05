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
    "ftp-backup"
    "keep-directory-diff"
    "link-to-copy"
    "nix-shell-init"
    "normalize-file-permissions"
    "run-efi"
    "qemu-uefi"
  ]
