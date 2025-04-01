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
    meta = {
      mainProgram = "ddns-update";
    };
  }
  ''
    mkdir -p $out/bin
    install -m +x ${./ddns-update.sh} $out/bin/ddns-update

    wrapProgram $out/bin/ddns-update \
      --prefix PATH : ${lib.makeBinPath deps}
  ''
