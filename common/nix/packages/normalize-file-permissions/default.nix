{
  makeWrapper,
  runCommand,
  lib,

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
runCommand "normalize-file-permissions"
  {
    nativeBuildInputs = [ makeWrapper ];
    meta = {
      mainProgram = "normalize-file-permissions";
    };
  }
  ''
    mkdir -p $out/bin
    install -m +x ${./normalize-file-permissions.sh} $out/bin/normalize-file-permissions

    wrapProgram $out/bin/normalize-file-permissions \
      --prefix PATH : ${lib.makeBinPath deps}
  ''
