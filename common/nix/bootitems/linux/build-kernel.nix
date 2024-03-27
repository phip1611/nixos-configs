{ lib
, linuxKernel # Build derivation for Linux kernel from `pkgs`.
, stdenv

  # Linux kernel package (from `pkgs.linux_*`) to get the source from.
, kernelPkg
}:

let
  # Function that builds a kernel from the provided Linux source with the
  # given config.
  buildKernel = kernelSrc: linuxKernel.manualConfig {
    inherit lib stdenv;

    src = kernelSrc.src;
    configfile = ./minimal-kernel.config;

    version = "${kernelSrc.version}";
    modDirVersion = "${kernelSrc.version}-minimal";

    # allowImportFromDerivation = true;
  };
in
buildKernel kernelPkg
