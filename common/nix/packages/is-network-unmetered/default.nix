{
  lib,
  makeWrapper,
  runCommand,
  # runtime deps
  bash,
  gawk,
  iproute2,
  networkmanager,
}:

let
  deps = [
    bash
    gawk
    iproute2
    networkmanager
  ];
in
runCommand "is-network-unmetered"
  {
    nativeBuildInputs = [ makeWrapper ];
    meta = {
      mainProgram = "is-network-unmetered";
    };
  }
  ''
    mkdir -p $out/bin
    install -m +x ${./is-network-unmetered.sh} $out/bin/is-network-unmetered

    wrapProgram $out/bin/is-network-unmetered \
      --prefix PATH : ${lib.makeBinPath deps}
  ''
