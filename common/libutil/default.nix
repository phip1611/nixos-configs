# Bundles and exports all sub modules of the "libutil" nix library.

{ pkgs }:

rec {
  ansi = import ./ansi { };
  builders = import ./builders { inherit (pkgs) runCommandLocal; };
  images = import ./images {
    inherit (pkgs)
      ansi lib grub2 grub2_efi writeTextFile runCommandNoCC writeShellScriptBin
      xorriso;
  };
  customPkgs = (import ./custom-pkgs {
    inherit (pkgs) callPackage;
  });
  trace = (import ./trace {
    inherit ansi;
    inherit (pkgs.lib.generators) toPretty;
  });
  writers = import ./writers { inherit (pkgs) callPackage; };
}
