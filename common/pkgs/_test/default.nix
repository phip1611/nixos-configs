{ pkgs
, libutil ? import ../../libutil { inherit pkgs; }
, commonPkgs ? import ../. { inherit pkgs; }
}:

let
  tests = import ./tests.nix {
    inherit pkgs;
    inherit libutil;
    inherit commonPkgs;
  };
in
pkgs.symlinkJoin {
  name = "libutil-tests";

  # Actual tests:
  paths = [

    # Check that
    # - create iso and efi works
    # - run-efi works
    # - the generated ISO and EFI indeed boot the kernel via Multiboot
    tests.kernel.testRunIso
    tests.kernel.testRunEfiMb1
    tests.kernel.testRunEfiMb2
  ];
}
