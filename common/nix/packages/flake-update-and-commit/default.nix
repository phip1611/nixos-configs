{
  lib,
  makeWrapper,
  runCommand,
  # runtime deps
  bash,
  git,
  nix,
  openssh, # for git+ssh dependencies
}:

let
  deps = [
    bash
    git
    nix
    openssh
  ];
in
runCommand "flake-update-and-commit"
  {
    nativeBuildInputs = [ makeWrapper ];
    meta = {
      mainProgram = "flake-update-and-commit";
    };
  }
  ''
    mkdir -p $out/bin
    install -m +x ${./flake-update-and-commit.sh} $out/bin/flake-update-and-commit

    wrapProgram $out/bin/flake-update-and-commit \
      --prefix PATH : ${lib.makeBinPath deps}
  ''
