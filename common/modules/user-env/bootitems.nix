{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.user-env;
  bootitems = pkgs.phip1611.bootitems;
  libutil = pkgs.phip1611.libutil;
in
{
  config = lib.mkIf (cfg.enable && cfg.withBootitems) {
    environment.etc."bootitems/tinytoykernel.elf32".source = "${bootitems.tinytoykernel}/kernel.elf32";
    environment.etc."bootitems/tinytoykernel.elf64".source = "${bootitems.tinytoykernel}/kernel.elf64";
    environment.etc."bootitems/linux/kernel_minimal_latest.bzImage".source = "${bootitems.linux.kernels.latest}/bzImage";
    environment.etc."bootitems/linux/kernel_minimal_latest.vmlinux".source = "${libutil.builders.extractVmlinux bootitems.linux.kernels.latest}/vmlinux";
    environment.etc."bootitems/linux/initrd_minimal".source = "${bootitems.linux.initrds.default}/initrd";
  };
}
