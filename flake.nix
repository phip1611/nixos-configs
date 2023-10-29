{
  description = "System Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    # Use nixpkgs-unstable instead of master so that packages are more likely
    # to be cached already while still being as fresh as possible.
    # See https://discourse.nixos.org/t/differences-between-nix-channels/13998
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/release-23.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    phip1611-common = {
      type = "github";
      owner = "phip1611";
      repo = "dotfiles";
      dir = "NixOS";
      # ref = "zsh-history";
    };

  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-unstable
    , home-manager
    , phip1611-common
    , flake-parts
    , ...
    }@inputs:
    let
      # Common modules that are added to each NixOS system. Here, I primarily add
      # modules that come from a flake.
      commonNixosModules = [
        home-manager.nixosModules.home-manager
        phip1611-common.nixosModules.phip1611-common
      ];
      # Helper function to build a NixOS system from a configuration and the
      # necessary flake inputs.
      buildNixosSystem =
        { hostName # string
        , system ? "x86_64-linux" # One of the definitions of `pkgs.lib.systems.flakeExposed`
          # NixOS modules defining the system. The idea here is to only provide
          # one `configuration.nix` and this file then imports all other files
          # of the configuration. This way, the NixOS system and the flake
          # definitions can be better separated and the NixOS configurations
          # are less dependent on flakes.
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
          nixosConfigurations =
            {
              # My personal PC at home where I've also have my Windows installed
              # (on a dedicated disk).
              homepc = buildNixosSystem {
                hostName = "phips-homepc";
                system = "x86_64-linux";
                nixosModules = [
                  ./hosts/homepc/configuration.nix
                ];
              };

              # My main laptop.
              linkin-park = buildNixosSystem {
                hostName = "linkin-park";
                system = "x86_64-linux";
                nixosModules = [
                  ./hosts/linkin-park/configuration.nix
                ];
              };
            };
        };
        # Systems definition for dev shells and exported packages,
        # independent of the NixOS configurations.
        systems = [
          "x86_64-linux"
        ];

        perSystem = { config, pkgs, ... }: {
          devShells = {
            default = pkgs.mkShell {
              packages = with pkgs; [
                nixos-rebuild
                nixpkgs-fmt
              ];
            };
          };

          formatter = pkgs.nixpkgs-fmt;
        };
      };
}
