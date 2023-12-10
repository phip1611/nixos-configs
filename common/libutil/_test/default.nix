{ pkgs
}:

let
  libutil = import ../. { inherit pkgs; };
  tests = import ./tests.nix {
    inherit pkgs;
    inherit libutil;
  };
in
pkgs.symlinkJoin {
  name = "libutil-tests";

  # Actual tests:
  paths = [
    # Check builders
    tests.builders.testFlattened
    tests.builders.testUnflattened

    # Check that
    # - create iso and efi works
    # - run-efi works
    # - the generated ISO and EFI indeed boot the kernel via Multiboot
    tests.kernel.testRunIso
    tests.kernel.testRunEfiMb1
    tests.kernel.testRunEfiMb2
  ];
}
