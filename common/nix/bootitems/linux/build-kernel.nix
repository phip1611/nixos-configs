{
  lib,
  linuxKernel, # Build derivation for Linux kernel from `pkgs`.
  stdenv,

  # Linux kernel package (from `pkgs.linux_*`) to get the source from.
  kernelSrc,
}:

let
  # Function that builds a kernel from the provided Linux source with the
  # given config.
  buildKernel =
    kernelSrc:
    linuxKernel.manualConfig {
      inherit lib stdenv;

      src = kernelSrc.src;
      configfile = ./minimal-kernel.config;

      version = kernelSrc.version;
      modDirVersion = "${kernelSrc.modDirVersion}-minimal";

      # allowImportFromDerivation = true;
    };
in
buildKernel kernelSrc
