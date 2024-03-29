# Lists the NixOS options of my NixOS common module.
{ home-manager
, nixpkgs
, ansi
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

      phip1611.common.user-env.enable = true;
      phip1611.common.user-env.git.email = "phip1611@gmail.com";
      phip1611.common.user-env.git.username = "Philipp Schuster";
      phip1611.common.system.enable = true;
      phip1611.network-boot.enable = true;
      phip1611.network-boot.interfaces = []; # remove used but not defined error
    }
  '';
in
writeShellScriptBin "list-phip1611-common-module-nixos-options" ''
  export PATH="${lib.makeBinPath [ansi nixos-option]}:$PATH"
  export NIX_PATH="nixpkgs=${nixpkgs}"
  export NIXOS_CONFIG=${minimalNixOSModule}

  echo -ne "$(ansi bold)Printing all configuration options of the phip1611 common module$(ansi reset) "
  echo -e "$(ansi bold)with their default value:$(ansi reset)"

  nixos-option phip1611 -r
''
