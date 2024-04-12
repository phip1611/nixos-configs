{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.user-env;
  bootitems = pkgs.phip1611.bootitems;
  libutil = pkgs.phip1611.libutil;
in
{
  config = lib.mkIf (cfg.enable && cfg.withBootitems) {
    environment.etc = ({
      "bootitems/tinytoykernel.elf32".source = "${bootitems.tinytoykernel}/kernel.elf32";
      "bootitems/tinytoykernel.elf64".source = "${bootitems.tinytoykernel}/kernel.elf64";
      "bootitems/linux/initrd_minimal".source = "${bootitems.linux.initrds.default}/initrd";
    } // (
      (builtins.foldl'
        (acc: kernel: acc // {
          "bootitems/linux/kernel_minimal_${kernel.version}.bzImage".source = "${kernel}/bzImage";
          "bootitems/linux/kernel_minimal_${kernel.version}.vmlinux".source = "${libutil.builders.extractVmlinux kernel}/vmlinux";
        })
        { }
        (builtins.attrValues bootitems.linux.kernels)
      )
    ));
  };
}
