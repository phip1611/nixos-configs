{ pkgs }:

let
  inherit (pkgs.phip1611) bootitems libutil packages;
in
{
  # Throughout test suite that combines a lot of my utility functions.
  # For example, this tests the whole chain from EFI image creation to EFI image
  # execution.
  kernelboot =
    let
      bootitem = rec {
        # Multiboot kernel in different formats, as Multiboot1 loaders usually
        # only load ELF32 files.
        elf32 = libutil.builders.flattenDrv { drv = bootitems.tinytoykernel; artifactPath = "kernel.elf32"; };
        elf64 = libutil.builders.flattenDrv { drv = bootitems.tinytoykernel; artifactPath = "kernel.elf64"; };
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
        efi = mb: libutil.images.x86.createMultibootEfi {
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
      bootWithTimeout = classifier: expectedOut: runCmd: pkgs.runCommand "test-boot-${classifier}"
        {
          nativeBuildInputs = [
            pkgs.ansi
            pkgs.cloud-hypervisor
            pkgs.qemu
            packages.run-efi
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
    in
    {
      testRunQemuDirect = bootWithTimeout "iso" "32 bit via MB1" "qemu-system-x86_64 -kernel ${bootitem.elf32} ${commonQemuArgs}";
      testRunQemuEfiMb1 = bootWithTimeout "efi-mb1" "32 bit via MB1" "run-efi --no-common-options --qemu-args='${commonQemuArgs}' ${bootitem.efiMb1}";
      testRunQemuEfiMb2 = bootWithTimeout "efi-mb2" "64 bit via MB2" "run-efi --no-common-options --qemu-args='${commonQemuArgs}' ${bootitem.efiMb2}";
      testRunQemuIso = bootWithTimeout "iso-hybrid-bios" "32 bit via MB2" "qemu-system-x86_64 -cdrom ${bootitem.iso} ${commonQemuArgs}";
      # It surprises me that this doesn't tell 64-bit, as CSM support was
      # removed from OVMF: https://github.com/NixOS/nixpkgs/pull/291963. Somehow,
      # the handoff doesnt happen from BOOTX64.EFI, I assume at least.
      # Otherwise, I would have expected AMD 64-bit AMD machine state.
      testRunQemuIsoUefi = bootWithTimeout "iso-hybrid-uefi" "32 bit via MB2" "qemu-system-x86_64 -cdrom ${bootitem.iso} -bios ${pkgs.OVMF.fd}/FV/OVMF.fd ${commonQemuArgs}";
      testRunXenPVH = bootWithTimeout "xen-pvh" "32 bit via Xen PVH" "cloud-hypervisor --console off --debug-console file=out.txt --kernel ${bootitem.elf64}";
    };
}
