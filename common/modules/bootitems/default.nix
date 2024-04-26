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
in
{
  options.phip1611.bootitems = {
    enable = lib.mkEnableOption "Place various ready-to-use bootitems (kernels, initrds) in /etc/bootitems for OS development";
  };
  config = lib.mkIf cfg.enable {
    environment.etc = ({
      "bootitems/tinytoykernel.elf32".source = "${bootitems.tinytoykernel}/kernel.elf32";
      "bootitems/tinytoykernel.elf64".source = "${bootitems.tinytoykernel}/kernel.elf64";
      "bootitems/linux/initrd_minimal".source = "${bootitems.linux.initrds.default}/initrd";
    } // (
      (builtins.foldl'
        (acc: kernel: acc // {
          "bootitems/linux/kernel_minimal_${kernel.version}.bzImage".source = "${kernel}/bzImage";
          "bootitems/linux/kernel_minimal_${stripMinorVersion kernel.version}.bzImage".source = "${kernel}/bzImage";

          "bootitems/linux/kernel_minimal_${kernel.version}.vmlinux".source = "${libutil.builders.extractVmlinux kernel}/vmlinux";
          "bootitems/linux/kernel_minimal_${stripMinorVersion kernel.version}.vmlinux".source = "${libutil.builders.extractVmlinux kernel}/vmlinux";
        })
        { }
        (builtins.attrValues bootitems.linux.kernels)
      )
    ));
  };
}
