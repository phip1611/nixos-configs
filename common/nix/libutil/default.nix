# Bundles and exports all modules of the "libutil" Nix library.

{ pkgs }:

rec {
  ansi = import ./ansi { };
  builders = import ./builders { inherit pkgs; };
  images = import ./images {
    inherit (pkgs)
      ansi
      lib
      grub2
      grub2_efi
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
