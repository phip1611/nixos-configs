{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.user-env;
  bootitems = pkgs.phip1611.bootitems;
in
{
  config = lib.mkIf (cfg.enable && cfg.withBootitems) {
    environment.etc."bootitems/tinytoykernel.elf32".source = "${bootitems.tinytoykernel}/kernel.elf32";
    environment.etc."bootitems/tinytoykernel.elf64".source = "${bootitems.tinytoykernel}/kernel.elf64";
    environment.etc."bootitems/minimal_linux_kernel_latest".source = "${bootitems.linux.kernels.latest}/bzImage";
    environment.etc."bootitems/minimal_linux_initrd".source = "${bootitems.linux.initrds.default}/initrd";
  };
}
