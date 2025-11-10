{
  config,
  lib,
  pkgs,
  ...
}@inputs:

let
  cfg = config.phip1611.bootitems;
  bootitems = pkgs.phip1611.bootitems;
  libutil = pkgs.phip1611.libutil;

  pkgsUnstable = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
  };

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
      # Not yet in Hydra / NixOS Cache
      # "bootitems/rust-hypervisor-firmware".source = "${pkgsUnstable.rust-hypervisor-firmware}/shell.efi";
      "bootitems/edk2-uefi-shell.efi".source = "${pkgsUnstable.edk2-uefi-shell}/shell.efi";
      "bootitems/OVMF_CODE.fd".source = "${pkgsUnstable.OVMF.fd}/FV/OVMF_CODE.fd";
      "bootitems/OVMF.fd".source = "${pkgsUnstable.OVMF.fd}/FV/OVMF.fd";
      "bootitems/tinytoykernel.elf32".source = "${bootitems.tinytoykernel}/kernel.elf32";
      "bootitems/tinytoykernel.elf64".source = "${bootitems.tinytoykernel}/kernel.elf64";
      "bootitems/tinytoykernel.efi".source = "${libutil.images.x86.createMultibootEfi {
        kernel = tinyToyKernelElf64;
      }}";
      "bootitems/tinytoykernel.iso".source = "${libutil.images.x86.createMultibootIso {
        kernel = tinyToyKernelElf64;
      }}";
    }
    //
      # Maḱe the linux kernels accessible in "/etc/bootitems" as vmlinux (ELF)
      # and bzImage with a path reflecting the version number (x.y and x.y.z).
      #
      # The attribute name corresponds to the symlink name.
      (lib.concatMapAttrs (
        name: kernel:
        let
          bzImage = "${kernel}/bzImage";
          vmlinux = "${libutil.builders.extractVmlinux kernel}/vmlinux";
          prefix = "bootitems/linux/kernel_minimal";
        in
        {
          "${prefix}/${name}.bzImage".source = bzImage;
          "${prefix}/${name}.vmlinux".source = vmlinux;
        }
      ) bootitems.linux.kernels)
    //
      # Maḱe the initrds accessible.
      #
      # The attribute name corresponds to the symlink name.
      (lib.concatMapAttrs (
        name: initrd:
        let
          prefix = "bootitems/linux/initrd_minimal";
        in
        {
          "${prefix}/${name}".source = "${initrd}/initrd";
        }
      ) bootitems.linux.initrds);
  };
}
