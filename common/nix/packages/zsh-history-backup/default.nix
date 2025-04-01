{
  lib,
  makeWrapper,
  runCommand,
  # runtime deps
  bash,
  zsh,
  zstd,
}:

let
  deps = [
    bash
    zsh
    zstd
  ];
in
runCommand "zsh-history-backup"
  {
    nativeBuildInputs = [ makeWrapper ];
    meta = {
      mainProgram = "zsh-history-backup";
    };
  }
  ''
    mkdir -p $out/bin
    install -m +x ${./zsh-history-backup.sh} $out/bin/zsh-history-backup

    wrapProgram $out/bin/zsh-history-backup \
      --prefix PATH : ${lib.makeBinPath deps}
  ''
