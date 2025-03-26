{

  lib,
  makeWrapper,
  runCommand,
  # runtime deps
  ansi,
  argc,
}:

let
  src = ./.;
  deps = [
    ansi
    argc
  ];
in
runCommand "link-to-copy"
  {
    nativeBuildInputs = [ makeWrapper ];
  }
  ''
    mkdir -p $out/bin
    install -m +x ${src}/link-to-copy.sh $out/bin/link-to-copy

    wrapProgram $out/bin/link-to-copy \
      --inherit-argv0 \
      --prefix PATH : ${lib.makeBinPath deps}
  ''
