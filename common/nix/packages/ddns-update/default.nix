{ pkgs }:

let
  lib = pkgs.lib;
  script = builtins.readFile ./ddns-update.sh;
in
# script = lib.writeFile "ddns-update-script" (builtins.readFile ./ddns-update.sh);
pkgs.writeShellScriptBin "ddns-update" ''
  set -euo pipefail
  export PATH="${
    lib.makeBinPath (
      with pkgs;
      [
        argc
        ansi
        curl
        jq
      ]
    )
  }:$PATH"
  ${script}
''
