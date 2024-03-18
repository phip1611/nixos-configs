{ pkgs }:

let
  lib = pkgs.lib;
  script = builtins.readFile ./normalize-file-permissions.sh;
in
pkgs.writeShellScriptBin "normalize-file-permissions" ''
  set -euo pipefail
  export PATH="${lib.makeBinPath (with pkgs; [argc ansi fd]) }:$PATH"
  ${script}
''
