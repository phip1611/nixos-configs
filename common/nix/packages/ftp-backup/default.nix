{ lib
, makeWrapper
, runCommandLocal
, symlinkJoin

, ansi
, argc
, gnutar
, lftp
, zstd

, python3
}:

let
  shellScriptDeps = [ ansi argc gnutar lftp zstd ];
  shellScript = runCommandLocal "ftp-backup"
    {
      nativeBuildInputs = [ makeWrapper ];
    } ''
    set -euo pipefail

    mkdir -p $out/bin

    cp ${./ftp-backup.sh} $out/bin/ftp-backup
    wrapProgram $out/bin/ftp-backup \
      --inherit-argv0 \
      --prefix PATH : ${lib.makeBinPath shellScriptDeps}
  '';

  pythonScriptDeps = [ python3 shellScript ];
  pythonScript = runCommandLocal "ftp-backup-from-config"
    {
      nativeBuildInputs = [ makeWrapper ];
    } ''
    set -euo pipefail

    mkdir -p $out/bin

    cp ${./ftp-backup-from-config.py} $out/bin/ftp-backup-from-config
    wrapProgram $out/bin/ftp-backup-from-config \
      --inherit-argv0 \
      --prefix PATH : ${lib.makeBinPath pythonScriptDeps}
  '';
in
symlinkJoin {
  name = "ftp-backup";
  paths = [
    shellScript
    pythonScript
  ];
}
