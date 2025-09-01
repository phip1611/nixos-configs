{
  lib,
  strace,
  writeShellScriptBin,
}:
let
  colorPatchSrc =
    let
      # Chosen from: https://github.com/xfgusta/strace-with-colors/commits/main
      rev = "c1e6b62659d26fed4f717d638319e287db5f1200";
      sha256 = "sha256:0s6i6wsdxysvb61srdzjj8s227pk081pwy8jzlbl2jlyiy0wdgr6";
      # sha256 = lib.fakeSha256;
    in
    builtins.fetchTarball {
      inherit sha256;
      url = "https://github.com/xfgusta/strace-with-colors/archive/${rev}.zip";
    };
  straceWithPatch = strace.overrideAttrs {
    patches = [
      ("${colorPatchSrc}/strace-with-colors.patch")
    ];
  };
in
writeShellScriptBin "strace-with-colors" "exec -a $0 ${straceWithPatch}/bin/strace $@"
