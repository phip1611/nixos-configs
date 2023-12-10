# List of tests for libutil.
#
# Each actual test (not helper attribute) should be prefixed with "test" and
# evaluates to a derivation that either succeeds or fails. Further, all test
# attributes must be non-flat derivations, i.e., produce an out directory and
# not a single file, so that they can be passed to symlinkJoin.

{ pkgs
, libutil
}:

let
  # Helper that transforms a bash condition to a succeeding or failing
  # derivation.
  bashCondToDrv = testName: bashCond: pkgs.runCommandLocal "bash-cond-to-drv-${testName}"
    {
      nativeBuildInputs = [ pkgs.ansi ];
    } ''
    # Bash strict mode.
    set -euo pipefail

    set +e
    if [[ ${bashCond} ]]; then
      mkdir $out
      exit 0
    fi
    set -e

    echo -e "$(ansi bold)$(ansi red)Condition '${bashCond}' for test '${testName}' not met!$(ansi reset)"
    exit 1
  '';

  builders = rec {
    base = pkgs.hello;
    flattened = libutil.builders.flattenDrv {
      drv = base;
      artifactPath = "bin/hello";
    };
    unflattened = libutil.builders.unflattenDrv {
      drv = flattened;
      artifactPath = "bin/hello";
    };
    testFlattened = bashCondToDrv "testFlattened" "-L ${flattened} || -f ${flattened}";
    testUnflattened = bashCondToDrv "testUnflattened" "-d ${unflattened}";
  };
  # Throughout test suite that combines a lot of my utility functions.
  # For example, this tests the whole chain from EFI image creation to EFI image
  # execution.
  kernel = rec {
    multiboot = pkgs.callPackage ./multiboot-kernel { };
    elf32 = libutil.builders.flattenDrv { drv = multiboot; artifactPath = "kernel.elf32"; };
    elf64 = libutil.builders.flattenDrv { drv = multiboot; artifactPath = "kernel.elf64"; };
    iso = libutil.images.x86.createBootableMultibootIso {
      kernel = elf32;
      multibootVersion = 1;
      bootModules = [
        {
          file = elf32;
          cmdline = "some additional boot module";
        }
      ];
    };
    efi = mb: libutil.images.x86.createBootableMultibootEfi {
      kernel = elf64;
      multibootVersion = mb;
      bootModules = [
        {
          file = elf32;
          cmdline = "some additional boot module";
        }
      ];
    };
    efiMb1 = efi 1;
    efiMb2 = efi 2;

    # File where the output of the booted kernel is stored.
    bootOutputFile = "out.txt";
    bootWithTimeout = classifier: expectedOut: runCmd: pkgs.runCommandNoCC "test-boot-${classifier}"
      {
        nativeBuildInputs = [
          pkgs.ansi
          pkgs.qemu
          libutil.customPkgs.run-efi
        ];
      } ''
      # Bash strict mode.
      set -euo pipefail

      echo -e "$(ansi bold)Executing: ${runCmd}$(ansi reset)"
      # timeout 7s: QEMU+OVMF quite needs some time to boot (without KVM)
      timeout --signal kill 7s ${runCmd} || \
        (echo -e "$(ansi bold)$(ansi red)VMM timed out when booting \
         ${classifier}:$(ansi reset)" && exit 1)
      grep -q "${expectedOut}" ${bootOutputFile}

      mkdir $out
    '';
    # Machine q35 necessary for UEFI, otherwise it doesn't boot.
    commonQemuArgs = "-debugcon file:${bootOutputFile} -no-reboot -display none -machine q35";
    testRunIso = bootWithTimeout "iso" "mb1" "qemu-system-x86_64 -cdrom ${kernel.iso} ${commonQemuArgs}";
    testRunEfiMb1 = bootWithTimeout "efi-mb1" "mb1" "run-efi --no-common-options --qemu-args='${commonQemuArgs}' ${kernel.efiMb1}";
    testRunEfiMb2 = bootWithTimeout "efi-mb2" "mb2" "run-efi --no-common-options --qemu-args='${commonQemuArgs}' ${kernel.efiMb2}";
  };
in
{
  inherit builders kernel;
}
