{
  callPackage,
  lib,
  makeWrapper,
  runCommand,
  # runtime deps
  bash,
  coreutils,
  rustup,
}:

let
  deps = [
    bash
    coreutils
    (callPackage ../is-network-unmetered { })
    rustup
  ];
in
runCommand "rustup-toolchains-update"
  {
    nativeBuildInputs = [ makeWrapper ];
    meta = {
      mainProgram = "rustup-toolchains-update";
    };
  }
  ''
    mkdir -p $out/bin
    install -m +x ${./rustup-toolchains-update.sh} $out/bin/rustup-toolchains-update

    wrapProgram $out/bin/rustup-toolchains-update \
      --prefix PATH : ${lib.makeBinPath deps}
  ''
