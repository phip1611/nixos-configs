{
  lib,
  makeWrapper,
  runCommand,
  # runtime deps
  bash,
  findutils,
  gnugrep,
}:

let
  deps = [
    bash
    findutils
    gnugrep
  ];
in
runCommand "cargo-clean-stale"
  {
    nativeBuildInputs = [ makeWrapper ];
    meta = {
      mainProgram = "cargo-clean-stale";
    };
  }
  ''
    mkdir -p $out/bin
    install -m +x ${./cargo-clean-stale.sh} $out/bin/cargo-clean-stale

    wrapProgram $out/bin/cargo-clean-stale \
      --prefix PATH : ${lib.makeBinPath deps}
  ''
