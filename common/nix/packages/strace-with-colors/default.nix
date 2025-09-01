{
  lib,
  strace,
  writeShellScriptBin,
}:
let
  colorPatchSrc = builtins.fetchTarball {
    url = "https://github.com/xfgusta/strace-with-colors/archive/refs/heads/main.tar.gz";
    sha256 = "sha256:0s6i6wsdxysvb61srdzjj8s227pk081pwy8jzlbl2jlyiy0wdgr6";
    # sha256 = lib.fakeSha256;
  };
  straceWithPatch = strace.overrideAttrs {
    patches = [
      ("${colorPatchSrc}/strace-with-colors.patch")
    ];
  };
in
writeShellScriptBin "strace-with-colors" "exec -a $0 ${straceWithPatch}/bin/strace $@"
