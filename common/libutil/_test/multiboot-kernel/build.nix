# Build the kernel.

{ grub2, lib, stdenv }:

stdenv.mkDerivation {
  name = "libutil-test-multiboot-kernel";
  nativeBuildInputs = [
    grub2
  ];
  src = lib.sourceByRegex ./. [
    "kernel.S"
    "link.lds"
    "Makefile"
  ];
  installPhase = ''
    mkdir $out
    cp kernel.elf32 $out
    cp kernel.elf64 $out
  '';
}
