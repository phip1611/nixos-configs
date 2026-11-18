{
  makeWrapper,
  runCommand,
  lib,

  # runtime deps
  ansi,
  argc,
  bash,
  coreutils,
  exiftool,
  fd,
}:

let
  deps = [
    ansi
    argc
    bash
    coreutils
    exiftool
    fd
  ];
in
runCommand "rename-photos-by-date"
  {
    nativeBuildInputs = [ makeWrapper ];
    meta = {
      mainProgram = "rename-photos-by-date";
    };
  }
  ''
    mkdir -p $out/bin
    install -m +x ${./rename-photos-by-date.sh} $out/bin/rename-photos-by-date

    wrapProgram $out/bin/rename-photos-by-date \
      --prefix PATH : ${lib.makeBinPath deps}
  ''
