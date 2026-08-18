{
  lib,
  makeWrapper,
  runCommand,

  # runtime deps
  bash,
  coreutils,
  dosfstools,
  fzf,
  gawk,
  parted,
  util-linux,
}:

let
  deps = [
    bash
    coreutils
    dosfstools
    fzf
    gawk
    parted
    util-linux
  ];
in
runCommand "format-usb-drive-bootable"
  {
    nativeBuildInputs = [ makeWrapper ];
    meta = {
      description = "Interactively prepare removable USB drives for EFI boot files";
      mainProgram = "format-usb-drive-bootable";
    };
  }
  ''
    mkdir -p $out/bin
    install -m +x ${./format-usb-drive-bootable.sh} $out/bin/format-usb-drive-bootable

    wrapProgram $out/bin/format-usb-drive-bootable \
      --prefix PATH : ${lib.makeBinPath deps}
  ''
