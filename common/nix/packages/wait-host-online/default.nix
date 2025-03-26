{
  argc,
  lib,
  makeWrapper,
  runCommand,
}:

let
  src = ./.;
  deps = [ argc ];
in
runCommand "wait-host-online"
  {
    nativeBuildInputs = [ makeWrapper ];
  }
  ''
    mkdir -p $out/bin
    install -m +x ${src}/wait-host-online.sh $out/bin/wait-host-online

    wrapProgram $out/bin/wait-host-online \
      --inherit-argv0 \
      --prefix PATH : ${lib.makeBinPath deps}
  ''
