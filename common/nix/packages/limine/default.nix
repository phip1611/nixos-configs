# Builds limine with all available features.

{ gcc, gnumake, mtools, nasm, stdenv }:

let
  # It is recommended by limine to use the release tarballs instead the git repo.
  limineUrl = "https://github.com/limine-bootloader/limine/releases/download/v7.0.2/limine-7.0.2.tar.gz";
  limineSrc = builtins.fetchTarball {
    url = limineUrl;
    sha256 = "sha256:0h70hkzyxpavsa896mj8pqc4gr6hj0bb2d76prp0rsgy1syyy9kc";
  };
in
stdenv.mkDerivation {
  pname = "limine";
  version = "7.0.2";
  src = limineSrc;
  nativeBuildInputs = [ mtools gnumake gcc nasm ];
  doCheck = false;
  # TODO missing --enable-uefi-{aarch64,riscv64} cross compilation so far
  configurePhase = ''
    ./configure \
      --enable-bios-cd \
      --enable-bios-pc \
      --enable-bios-pxe \
      --enable-uefi-ia32 \
      --enable-uefi-x86-64 \
      --enable-uefi-cd
  '';
  buildPhase = ''
    make -j $(nproc)
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp -R bin/. $out
    ln -s $out/limine $out/bin/limine
  '';
}
