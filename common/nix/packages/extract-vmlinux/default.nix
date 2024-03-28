# Extracts <linux-latest-src>/scripts/extract-vmlinux as package. As this script
# is rather basic and generic, we do not need to care about the specific Linux
# src version from that we get the script.

{ lib
, linux_latest # kernel package to get the source tree from
, makeWrapper
, runCommandLocal

, binutils # readelf
, coreutils
, gnugrep

  # decompressors for possible kernel image formats
, bzip2
, gzip
, lz4
, lzop
, xz
, zstd
}:

let
  deps = [
    binutils
    coreutils
    gnugrep
    gzip
    xz
    bzip2
    lzop
    lz4
    zstd
  ];
in
runCommandLocal "extract-vmlinux-${toString linux_latest.version}"
{
  nativeBuildInputs = [ makeWrapper ];
} ''
  set -euo pipefail

  mkdir -p $out/bin

  tar xf ${linux_latest.src} # untar the .tar.xz file
  cp ./linux-${toString linux_latest.version}/scripts/extract-vmlinux $out/bin

  wrapProgram $out/bin/extract-vmlinux \
    --prefix PATH : ${lib.makeBinPath deps}
''
