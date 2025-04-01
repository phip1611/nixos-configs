{
  lib,
  makeWrapper,
  runCommand,
  # runtime deps
  argc,
  bash,
}:

let
  deps = [
    argc
    bash
  ];
in
runCommand "wait-host-online"
  {
    nativeBuildInputs = [ makeWrapper ];
    meta = {
      mainProgram = "wait-host-online";
    };
  }
  ''
    mkdir -p $out/bin
    install -m +x ${./wait-host-online.sh} $out/bin/wait-host-online

    wrapProgram $out/bin/wait-host-online \
      --prefix PATH : ${lib.makeBinPath deps}
  ''
