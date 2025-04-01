{

  lib,
  makeWrapper,
  runCommand,
  # runtime deps
  ansi,
  argc,
  bash,
}:

let
  deps = [
    ansi
    argc
    bash
  ];
in
runCommand "link-to-copy"
  {
    nativeBuildInputs = [ makeWrapper ];
    meta = {
      mainProgram = "link-to-copy";
    };
  }
  ''
    mkdir -p $out/bin
    install -m +x ${./link-to-copy.sh} $out/bin/link-to-copy

    wrapProgram $out/bin/link-to-copy \
      --prefix PATH : ${lib.makeBinPath deps}
  ''
