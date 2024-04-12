{ ansi
, argc
, lib
, makeWrapper
, runCommandLocal
}:

let
  src = ./.;
  deps = [ ansi argc ];
in
runCommandLocal "link-to-copy"
{
  nativeBuildInputs = [ makeWrapper ];
} ''
  set -euo pipefail

  mkdir -p $out/bin

  cp ${src}/link-to-copy.sh $out/bin/link-to-copy

  chmod +x $out/bin/link-to-copy
  wrapProgram $out/bin/link-to-copy \
    --prefix PATH : ${lib.makeBinPath deps}
''
