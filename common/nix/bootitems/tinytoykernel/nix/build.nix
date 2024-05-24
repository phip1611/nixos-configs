# Build the kernel.

{ grub2
, nix-gitignore
, stdenv
}:

stdenv.mkDerivation {
  name = "tinytoykernel";
  src = nix-gitignore.gitignoreSource [ ] ./..;
  nativeBuildInputs = [
    grub2 # for grub-file
  ];
  installPhase = ''
    mkdir $out
    cp build/kernel.elf32 $out
    cp build/kernel.elf64 $out
  '';
}
