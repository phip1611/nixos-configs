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
runCommand "flake-prefetch"
  {
    nativeBuildInputs = [ makeWrapper ];
    meta = {
      mainProgram = "flake-prefetch";
    };
  }
  ''
    mkdir -p $out/bin
    install -m +x ${./flake-prefetch.sh} $out/bin/flake-prefetch

    wrapProgram $out/bin/flake-prefetch \
      --prefix PATH : ${lib.makeBinPath deps}
  ''
