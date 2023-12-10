{
  description = "phip1611's common libraries, modules, and configurations for Nix and NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    # Use nixpkgs-unstable instead of master so that packages are more likely
    # to be cached already while still being as fresh as possible.
    # See https://discourse.nixos.org/t/differences-between-nix-channels/13998
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-unstable
    , home-manager
    , flake-parts
    , ...
    }@inputs:
    let
      libutilSrc = ./common/libutil;
      libutilTestsSrc = ./common/libutil/_test;
      phip1611-commonSrc = ./common;
      phip1611-commonModuleSrc = ./common/module;
      phip1611-commonModule = import phip1611-commonModuleSrc;

      # Common modules that are added to each NixOS system. Here, I primarily add
      # modules that come from a flake.
      commonNixosModules = [
        home-manager.nixosModules.home-manager
        phip1611-commonModule
      ];

      # Helper function to build a NixOS system with my common modules and
      # relevant special args.
      buildNixosSystem =
        { hostName # string
          # One of the definitions of `pkgs.lib.systems.flakeExposed`:
          # NixOS modules defining the system. The idea here is to only provide
          # one `configuration.nix` and this file then imports all other files
          # of the configuration. This way, the NixOS system and the flake
          # definitions can be better separated and the NixOS configurations
          # are less dependent on flakes.
        , system ? "x86_64-linux"
        , nixosModules ? [ ]
        }:
        (
          let
            # create a `pkgsUnstable` attribute that is similar usable as
            # `pkgs` in a NixOS module.
            pkgsUnstable = import nixpkgs-unstable {
              inherit system;
              config = {
                allowUnfree = true;
              };
            };
            additionalNixosModuleArguments = {
              inherit pkgsUnstable;
            };
          in
          nixpkgs.lib.nixosSystem {
            inherit system;
            # specialArgs:
            #   Additional arguments that are passed to a NixOS module
            #   function.
            specialArgs = inputs // additionalNixosModuleArguments // { inherit hostName; };
            modules = commonNixosModules ++ nixosModules;
          }
        );

    in
    flake-parts.lib.mkFlake { inherit inputs; }
      {
        flake = {
          # Here I simply re-export the library files without initializing
          # it with the nixpkgs input, i.e., this is no "per system" attribute.
          lib = rec {
            # You need to pass pkgs to this export.
            default = libutil;
            libutil = libutilSrc;
          };

          nixosConfigurations = {
            # My personal PC at home where I've also have my Windows installed
            # (on a dedicated disk).
            homepc = buildNixosSystem {
              hostName = "phips-homepc";
              system = "x86_64-linux";
              nixosModules = [
                ./nixos-configs/homepc/configuration.nix
              ];
            };

            # My main laptop.
            linkin-park = buildNixosSystem {
              hostName = "linkin-park";
              system = "x86_64-linux";
              nixosModules = [
                ./nixos-configs/linkin-park/configuration.nix
              ];
            };
          };

          nixosModules = {
            default = phip1611-commonModule;
            phip1611-common = phip1611-commonModule;
          };

        };

        # Systems definition for dev shells and exported packages,
        # independent of the NixOS configurations.
        systems = [
          "x86_64-linux"
        ];

        perSystem = { config, pkgs, ... }:
          let
            libutil = import libutilSrc { inherit pkgs; };
          in
          {
            # $ nix build .\#checks.x86_64-linux.<attribute-name>
            checks = rec {
              default = pkgs.symlinkJoin {
                name = "all-checks";
                paths = [
                  runLibutilTests
                ];
              };
              runLibutilTests = import libutilTestsSrc { inherit pkgs; };
            };

            devShells = {
              default = pkgs.mkShell {
                packages = with pkgs; [
                  nixos-rebuild
                  nixpkgs-fmt
                ] ++ builtins.attrValues libutil.customPkgs;
              };
            };

            formatter = pkgs.nixpkgs-fmt;

            # Everything under packages can also be run. So I don't quite get
            # the difference. So, I do not provide the `apps` key for now.
            #
            # $ nix build .\#packages.x86_64-linux.<attribute-name>
            # $ nix run .\#<attribute-name>
            packages = {
              # TODO not sure why I can't put this under apps.
              listNixosOptions = import ./test/pkgs/list-nixos-options.nix {
                inherit (pkgs) lib nixos-option writeShellScriptBin writeText;
                inherit home-manager phip1611-commonSrc;
              };
            } // libutil.customPkgs;
          };
      };
}
