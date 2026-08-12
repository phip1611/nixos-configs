{
  lib,
  makeWrapper,
  runCommand,
  symlinkJoin,

  # runtime deps
  argc,
  bash,
}:

let
  shellScriptDeps = [
    argc
    bash
  ];
in
runCommand "repeat-cmd"
  {
    nativeBuildInputs = [ makeWrapper ];
    meta = {
      mainProgram = "repeat-cmd";
    };
  }
  ''
    mkdir -p $out/bin
    install -m +x ${./repeat-cmd.sh} $out/bin/repeat-cmd

    wrapProgram $out/bin/repeat-cmd \
      --prefix PATH : ${lib.makeBinPath shellScriptDeps}
  ''
