{
  makeWrapper,
  runCommand,
  lib,

  # runtime deps
  argc,
}:

let
  src = ./.;
  deps = [ argc ];
in
runCommand "normalize-file-permissions"
  {
    nativeBuildInputs = [ makeWrapper ];
  }
  ''
    mkdir -p $out/bin
    install -m +x ${src}/normalize-file-permissions.sh $out/bin/normalize-file-permissions

    wrapProgram $out/bin/normalize-file-permissions \
      --inherit-argv0 \
      --prefix PATH : ${lib.makeBinPath deps}
  ''
