{ lib
, makeWrapper
, runCommandLocal

, ansi
, argc
, gnutar
, lftp
, zstd
}:

let
  deps = [ ansi argc gnutar lftp zstd ];
in
runCommandLocal "ftp-backup"
{
  nativeBuildInputs = [ makeWrapper ];
} ''
  set -euo pipefail

  mkdir -p $out/bin

  cp ${./ftp-backup.sh} $out/bin/ftp-backup
  wrapProgram $out/bin/ftp-backup \
    --prefix PATH : ${lib.makeBinPath deps}
''
