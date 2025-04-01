{ strace, writeShellScriptBin }:
let
  colorPatchSrc = builtins.fetchTarball {
    url = "https://github.com/xfgusta/strace-with-colors/archive/refs/heads/main.tar.gz";
    sha256 = "sha256:1rgghm9knxhiw1m8sw0nim7x3qdd476d6sx83x0p3s6pc7fns3y4";
  };
  straceWithPatch = strace.overrideAttrs {
    patches = [
      ("${colorPatchSrc}/strace-with-colors.patch")
    ];
  };
in
writeShellScriptBin "strace-with-colors" "exec -a $0 ${straceWithPatch}/bin/strace $@"
