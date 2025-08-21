# nixpkgs fallback is only here for quick prototyping. See README.md.
{
  pkgs ? builtins.trace "WARN: Using nixpkgs from ./nixpkgs.nix" (import ./nixpkgs.nix),
}:

let
  tests = {
    # bootitemsTests = import ./bootitems/tests.nix { inherit pkgs; };
    combinedTests = import ./tests.nix { inherit pkgs; };
    libutilTests = import ./libutil/tests.nix { inherit pkgs; };
    # packagesTests = import ./packages/tests.nix { inherit pkgs; };
  };
  libutil = import ./libutil { inherit pkgs; };
  bootitems = import ./bootitems { inherit libutil pkgs; };
  packages = import ./packages { inherit pkgs; };
in
{
  inherit bootitems libutil packages;
  allTests = pkgs.symlinkJoin {
    name = "all-tests";
    paths = [
      # Check builders
      tests.libutilTests.builders.testFlattened
      tests.libutilTests.builders.testUnflattened

      # Check that
      # - tinytoykernel boots
      # - create .iso and .efi works
      # - run-efi works
      # - the generated ISO and EFI indeed boot the kernel via Multiboot
      tests.combinedTests.kernelboot.testRunQemuDirect
      tests.combinedTests.kernelboot.testRunQemuEfiMb1
      tests.combinedTests.kernelboot.testRunQemuEfiMb2
      tests.combinedTests.kernelboot.testRunQemuIso
      tests.combinedTests.kernelboot.testRunQemuIsoUefi
      tests.combinedTests.kernelboot.testRunQemuEfiMb1
      tests.combinedTests.kernelboot.testRunQemuEfiMb2
      tests.combinedTests.kernelboot.testRunXenPVH
    ];
  };

  # Useful for quick prototyping.
  /*
    iso = libutil.images.x86.createMultibootIso {
      kernel = (libutil.builders.flattenDrv {
        drv = bootitems.tinytoykernel;
        artifactPath = "kernel.elf64";
      }).overrideAttrs { name = "tinytoykernel"; };
    };
  */
}
