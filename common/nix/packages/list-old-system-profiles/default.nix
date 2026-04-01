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
runCommand "list-old-system-profiles"
  {
    nativeBuildInputs = [ makeWrapper ];
    meta = {
      mainProgram = "list-old-system-profiles";
    };
  }
  ''
    mkdir -p $out/bin
    install -m +x ${./list-old-system-profiles.sh} $out/bin/list-old-system-profiles

    wrapProgram $out/bin/list-old-system-profiles \
      --prefix PATH : ${lib.makeBinPath deps}
  ''
