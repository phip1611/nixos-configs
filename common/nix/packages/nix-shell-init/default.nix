{ writeShellScriptBin }:

writeShellScriptBin "nix-shell-init" ''
  set -euo pipefail

  if [ -e "$PWD/shell.nix" ]; then
    echo "$PWD/shell.nix already exists" >&2
    exit 1
  fi

  cp ${./nix-shell-init.template.txt} "$PWD/shell.nix"
  chmod u+w "$PWD/shell.nix"
''
