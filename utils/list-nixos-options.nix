# Lists all NixOS options of the common NixOS modules.

{ home-manager
, nixpkgs
, self

, ansi
, lib
, nixos-option
, writeShellScriptBin
, writeText
, ...
}:

let
  selfModules = builtins.attrValues self.nixosModules;
  # Not sure why, but it seems flake-parts transforms the modules to this
  # rather odd structure. The module path is the first (and only) element in
  # module.imports.
  extractModulePath = module: builtins.head module.imports;
  toModuleImportLine = module: "(import ${extractModulePath module})";
  combinedConfig = writeText "combined-config" ''
    {
      imports = [
        # Pre-reququisites
        (import ${home-manager}/nixos)
        ${builtins.concatStringsSep "\n" (map toModuleImportLine selfModules)}
      ];

      # Activate all default options
      phip1611.bootitems.enable = true;
      phip1611.common.system.enable = true;
      phip1611.common.user-env.enable = true;
      phip1611.network-boot.enable = true;

      # Remove some used but not defined errors.
      phip1611.common.user-env.username = "foobar123";
      phip1611.common.user-env.git.email = "phip1611n@gmail.com";
      phip1611.common.user-env.git.username = "Philipp Schuster";
      phip1611.network-boot.username = "foobar123";
      phip1611.network-boot.interfaces = [];
    }
  '';
in
writeShellScriptBin "list-common-nixos-options" ''
  export PATH="${lib.makeBinPath [ansi nixos-option]}:$PATH"
  export NIX_PATH="nixpkgs=${nixpkgs}"
  export NIXOS_CONFIG=${combinedConfig}

  echo -ne "$(ansi bold)Printing all configuration options of the phip1611 common module$(ansi reset) "
  echo -e "$(ansi bold)with their default value:$(ansi reset)"

  nixos-option phip1611 -r
''
