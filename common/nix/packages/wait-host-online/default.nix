{ argc
, lib
, makeWrapper
, runCommandLocal
}:

let
  src = ./.;
  deps = [ argc ];
in
runCommandLocal "wait-host-online"
{
  nativeBuildInputs = [ makeWrapper ];
} ''
  set -euo pipefail

  mkdir -p $out/bin

  cp ${src}/wait-host-online.sh $out/bin/wait-host-online

  chmod +x $out/bin/wait-host-online
  wrapProgram $out/bin/wait-host-online \
    --inherit-argv0 \
    --prefix PATH : ${lib.makeBinPath deps}
''
