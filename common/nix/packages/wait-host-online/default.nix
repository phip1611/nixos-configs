{
  lib,
  makeWrapper,
  runCommand,
  # runtime deps
  argc,
  bash,
  iputils,
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

    # iputils is only a fallback: a system ping, which might be a wrapper with
    # the required capabilities, takes precedence.
    wrapProgram $out/bin/wait-host-online \
      --prefix PATH : ${lib.makeBinPath deps} \
      --suffix PATH : ${lib.makeBinPath [ iputils ]}
  ''
