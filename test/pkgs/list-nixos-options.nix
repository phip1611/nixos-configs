# Lists the NixOS options of my NixOS common module.
{ home-manager
, phip1611-commonSrc
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
        (import "${phip1611-commonSrc}/module/default.nix")
      ];
    }
  '';
in
writeShellScriptBin "list-phip1611-common-module-nixos-options" ''
  export PATH="${lib.makeBinPath [nixos-option]}:$PATH"
  NIXOS_CONFIG=${minimalNixOSModule} nixos-option phip1611 -r
''
