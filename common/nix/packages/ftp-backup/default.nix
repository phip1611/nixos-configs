{
  lib,
  makeWrapper,
  runCommand,
  symlinkJoin,

  # runtime deps
  ansi,
  argc,
  gnutar,
  lftp,
  zstd,
  python3,
}:

let
  shellScriptDeps = [
    ansi
    argc
    gnutar
    lftp
    zstd
  ];
  shellScript =
    runCommand "ftp-backup"
      {
        nativeBuildInputs = [ makeWrapper ];
      }
      ''
        mkdir -p $out/bin
        install -m +x ${./ftp-backup.sh} $out/bin/ftp-backup

        wrapProgram $out/bin/ftp-backup \
          --inherit-argv0 \
          --prefix PATH : ${lib.makeBinPath shellScriptDeps}
      '';

  pythonScriptDeps = [
    python3
    shellScript
  ];
  pythonScript =
    runCommand "ftp-backup-from-config"
      {
        nativeBuildInputs = [ makeWrapper ];
      }
      ''
        mkdir -p $out/bin
        install -m +x ${./ftp-backup-from-config.py} $out/bin/ftp-backup-from-config

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
