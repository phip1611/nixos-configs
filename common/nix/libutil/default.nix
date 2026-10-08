# Bundles and exports all modules of the "libutil" Nix library.

{ pkgs }:

let
  # GRUB 2.14 maps module .text read-only but patches the x86 relocator
  # stubs in place, so every multiboot boot on UEFI page-faults. Fixed
  # upstream in 2.16.
  grub2_efi =
    if pkgs.lib.versionOlder pkgs.grub2_efi.version "2.16" then
      pkgs.grub2_efi.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          (pkgs.fetchpatch {
            name = "relocator-x86-place-runtime-patched-stubs-in-data.patch";
            url = "https://gitlab.freedesktop.org/gnu-grub/grub/-/commit/62289192bb45bd90f5917c53fd29083d9a9672b1.patch";
            hash = "sha256-Qf7u76S3B0yxvGvKwf0Eu8xaWjiqZp7SIgGZsRrGhss=";
          })
        ];
      })
    else
      pkgs.grub2_efi;
in
rec {
  ansi = import ./ansi { };
  builders = import ./builders { inherit pkgs; };
  images = import ./images {
    inherit grub2_efi;
    inherit (pkgs)
      ansi
      lib
      grub2
      limine
      writeTextFile
      runCommand
      writeShellScriptBin
      xorriso
      ;
  };
  testing = (
    import ./testing {
      inherit (pkgs)
        ansi
        runCommandLocal
        ;
    }
  );
  trace = (
    import ./trace {
      inherit ansi;
      inherit (pkgs.lib.generators) toPretty;
    }
  );
  writers = import ./writers { inherit (pkgs) callPackage; };
}
