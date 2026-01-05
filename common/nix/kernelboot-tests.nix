# Various kernel boot tests.
#
# Throughout test suite that combines a lot of my utility functions. For
# example, this tests the whole chain from EFI image creation to EFI image
# boot.

{ pkgs }:

let
  inherit (pkgs.phip1611) bootitems libutil packages;
  bootitem = rec {
    # Multiboot kernel in different formats, as Multiboot1 loaders usually
    # only load ELF32 files.
    elf32 = libutil.builders.flattenDrv {
      drv = bootitems.tinytoykernel;
      artifactPath = "kernel.elf32";
    };
    elf64 = libutil.builders.flattenDrv {
      drv = bootitems.tinytoykernel;
      artifactPath = "kernel.elf64";
    };
    # Hybrid bootable iso.
    iso = libutil.images.x86.createMultibootIso {
      kernel = elf64;
      multibootVersion = 2;
      bootModules = [
        {
          file = elf64;
          cmdline = "some additional boot module";
        }
      ];
    };
    efi =
      mb:
      libutil.images.x86.createMultibootEfi {
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
  };

  # File where the output of the booted kernel is stored.
  bootOutputFile = "out.txt";

  # timeout 7s: QEMU+OVMF needs quite some time to boot (without KVM)
  timeout_s = 7;

  # Helper function that boots a kernel and waits for expected kernel output
  # with a short timeout.
  bootWithTimeout =
    {
      # string: Classifier of the test
      classifier,
      # string: Output that is expected. This can be a substring.
      expectedOut,
      # string: Command line
      cmdline,
    }:
    pkgs.runCommand "test-boot-${classifier}"
      {
        nativeBuildInputs =
          (with pkgs; [
            ansi
            cloud-hypervisor
            qemu
          ])
          ++ [ packages.run-efi ];
      }
      ''
        # Bash strict mode.
        set -euo pipefail

        echo "Version overview:"
        echo "  Cloud Hypervisor: ${pkgs.cloud-hypervisor.version}"
        echo "  Limine          : ${pkgs.limine.version}"
        echo "  QEMU            : ${pkgs.qemu.version}"

        echo -e "$(ansi bold)Test: ${classifier}"
        echo -e "$(ansi bold)Executing: ${cmdline}$(ansi reset)"
        timeout --signal kill ${toString timeout_s}s ${cmdline} || \
          (echo -e "$(ansi bold)$(ansi red)VMM timed out when booting \
           ${classifier}:$(ansi reset)" && exit 1)
        grep -q "${expectedOut}" ${bootOutputFile}

        mkdir $out
      '';
  # Machine q35 necessary for UEFI, otherwise it doesn't boot.
  commonQemuArgs = "-debugcon file:${bootOutputFile} -no-reboot -display none -machine q35,accel=kvm -serial stdio";
in
{
  testRunQemuDirect = bootWithTimeout {
    classifier = "iso";
    expectedOut = "32 bit via MB1";
    cmdline = "qemu-system-x86_64 -kernel ${bootitem.elf32} ${commonQemuArgs}";
  };
  testRunQemuEfiMb1 = bootWithTimeout {
    classifier = "efi-mb1";
    expectedOut = "32 bit via MB1";
    cmdline = "run-efi --no-common-options --qemu-args='${commonQemuArgs}' ${bootitem.efiMb1}";
  };
  testRunQemuEfiMb2 = bootWithTimeout {
    classifier = "ef2-mb1";
    expectedOut = "64 bit via MB2";
    cmdline = "run-efi --no-common-options --qemu-args='${commonQemuArgs}' ${bootitem.efiMb2}";
  };
  testRunQemuIso = bootWithTimeout {
    classifier = "iso-hybrid-bios";
    expectedOut = "32 bit via MB2";
    cmdline = "qemu-system-x86_64 -cdrom ${bootitem.iso} ${commonQemuArgs}";
  };
  # It surprises me that this doesn't tell 64-bit, as CSM support was
  # removed from OVMF: https://github.com/NixOS/nixpkgs/pull/291963. Somehow,
  # the handoff doesnt happen from BOOTX64.EFI, I assume at least.
  # Otherwise, I would have expected AMD 64-bit AMD machine state.
  testRunQemuIsoUefi = bootWithTimeout {
    classifier = "iso-hybrid-uefi";
    expectedOut = "32 bit via MB2";
    cmdline = "qemu-system-x86_64 -cdrom ${bootitem.iso} -bios ${pkgs.OVMF.fd}/FV/OVMF.fd ${commonQemuArgs}";
  };
  testRunXenPVH = bootWithTimeout {
    classifier = "xen-pvh";
    expectedOut = "32 bit via Xen PVH";
    cmdline = "cloud-hypervisor --console off --debug-console file=out.txt --kernel ${bootitem.elf64}";
  };
}
