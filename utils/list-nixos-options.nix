# Lists all NixOS options of the common NixOS modules.

{
  self,

  ansi,
  lib,
  nixos-option,
  writeShellScriptBin,
  ...
}:

let
  DEFAULT_HOST = "homepc";
in
writeShellScriptBin "list-common-nixos-options" ''
  export PATH="${
    lib.makeBinPath [
      ansi
      nixos-option
    ]
  }:$PATH"

  echo -ne "$(ansi bold)Printing all configuration options of the phip1611 common module$(ansi reset) "
  echo -e "$(ansi bold)with their default value:$(ansi reset)"

  nixos-option --flake ${self}#${DEFAULT_HOST} phip1611 -r
''
