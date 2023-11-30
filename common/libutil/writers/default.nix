{ callPackage, }:

let
  writeZxScriptBin = callPackage ./write-zx-script-bin.nix { };
in
{
  inherit writeZxScriptBin;
}
