{
  lib,
  makeWrapper,
  runCommand,

  # runtime deps
  argc,
  ansi,
  curl,
  jq,
}:

let
  src = ./.;
  deps = [
    argc
    ansi
    curl
    jq
  ];
in
runCommand "ddns-update"
  {
    nativeBuildInputs = [ makeWrapper ];
  }
  ''
    mkdir -p $out/bin
    install -m +x ${src}/ddns-update.sh $out/bin/ddns-update

    wrapProgram $out/bin/ddns-update \
      --inherit-argv0 \
      --prefix PATH : ${lib.makeBinPath deps}
  ''
