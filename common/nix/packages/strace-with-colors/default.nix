{ strace, writeShellScriptBin }:
let
  straceWithPatch = strace.overrideAttrs {
    patches = [
      ./patch.patch
    ];
  };
in
writeShellScriptBin "strace-with-colors" "exec -a $0 ${straceWithPatch}/bin/strace $@"
