# Workaround as long as [0]/[1] are not resolved.
#
# [0] https://youtrack.jetbrains.com/issue/CPP-39605/CLion-Always-allow-Mark-Directory-as-Excluded-not-a-CMake-Project
# [1] https://youtrack.jetbrains.com/issue/CPP-13494/Mark-Directory-as-Excluded-should-be-available-even-when-CMake-is-not-loaded

{
  lib,
  writeShellScriptBin,

  # runtime deps
  argc,
  fd,
  python3Minimal,
}:

writeShellScriptBin "clion-exclude-direnv" ''
  # The following @-annotations belong to https://github.com/sigoden/argc
  #
  # @describe
  # Forcefully excludes `.direnv` in the <project>.iml file of the CLion
  # project. This tool must be invoked in the CLion project root, so that
  # the `$PWD/.idea/<project>.iml` file is reachable.

  set -euo pipefail

  export PATH="${
    lib.makeBinPath ([
      argc
      fd
      python3Minimal
    ])
  }:$PATH"

  # Do the "argc" magic. Reference: https://github.com/sigoden/argc
  eval "$(argc --argc-eval "$0" "$@")"

  PROJECT_FILE=$(fd --min-depth=1 --maxdepth=1 --extension=iml -u . ./.idea)
  SEARCH=$(cat ${./search.txt})
  REPLACE=$(cat ${./replace.txt})

  echo "PROJECT_FILE = $(realpath $PROJECT_FILE)"

  python ${./replace.py} "$PROJECT_FILE" "$SEARCH" "$REPLACE"
''
