{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.bootitems;
  bootitems = pkgs.phip1611.bootitems;
  libutil = pkgs.phip1611.libutil;

  # Transforms a version string from "1.2.3" to "1.2".
  stripMinorVersion = version: builtins.concatStringsSep
    "."
    (
      lib.take
        2
        (builtins.splitVersion version)
    );

  tinyToyKernelElf64 = libutil.builders.flattenDrv {
    drv = bootitems.tinytoykernel;
    artifactPath = "kernel.elf64";
  };
in
{
  options.phip1611.bootitems = {
    enable = lib.mkEnableOption "Place various ready-to-use bootitems (kernels, initrds) in /etc/bootitems for OS development";
  };
  config = lib.mkIf cfg.enable {
    # Pre-requisites
    phip1611.bootitems-overlay.enable = true;
    phip1611.libutil-overlay.enable = true;

    environment.etc = {
      "bootitems/edk2-uefi-shell.efi".source = "${pkgs.edk2-uefi-shell}/shell.efi";
      "bootitems/OVMF_CODE.fd".source = "${pkgs.OVMF.fd}/FV/OVMF_CODE.fd";
      "bootitems/OVMF.fd".source = "${pkgs.OVMF.fd}/FV/OVMF.fd";
      "bootitems/tinytoykernel.elf32".source = "${bootitems.tinytoykernel}/kernel.elf32";
      "bootitems/tinytoykernel.elf64".source = "${bootitems.tinytoykernel}/kernel.elf64";
      "bootitems/tinytoykernel.efi".source = "${libutil.images.x86.createMultibootEfi {
        kernel = tinyToyKernelElf64;
      }}";
      "bootitems/tinytoykernel.iso".source = "${libutil.images.x86.createMultibootIso {
        kernel = tinyToyKernelElf64;
      }}";
      "bootitems/linux/initrd_minimal".source = "${bootitems.linux.initrds.default}/initrd";
    } //
    # Make Linux kernels accessible by their exact version number and
    # "x.y" version format.
    (builtins.foldl'
      (acc: kernel: acc // (
        let
          prefix = "bootitems/linux/kernel_minimal";
          bzImage = "${kernel}/bzImage";
          vmlinux = "${libutil.builders.extractVmlinux kernel}/vmlinux";
        in
        {
          "${prefix}_${kernel.version}.bzImage".source = bzImage;
          "${prefix}_${stripMinorVersion kernel.version}.bzImage".source = bzImage;

          "${prefix}_${kernel.version}.vmlinux".source = vmlinux;
          "${prefix}_${stripMinorVersion kernel.version}.vmlinux".source = vmlinux;
        }
      ))
      { }
      (builtins.attrValues bootitems.linux.kernels)
    );
  };
}
