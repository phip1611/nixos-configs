# Lists the NixOS options of my NixOS common module.
{ home-manager
, nixpkgs
, commonSrc
, lib
, nixos-option
, writeShellScriptBin
, writeText
}:

let
  minimalNixOSModule = writeText "minimal-nixos-module" ''
    {
      imports = [
        (import ${home-manager}/nixos)
        (import "${commonSrc.module}")
      ];
    }
  '';
in
writeShellScriptBin "list-phip1611-common-module-nixos-options" ''
  export PATH="${lib.makeBinPath [nixos-option]}:$PATH"
  export NIX_PATH="nixpkgs=${nixpkgs}"
  export NIXOS_CONFIG=${minimalNixOSModule}
  nixos-option phip1611 -r
''
