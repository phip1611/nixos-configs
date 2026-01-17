{
  description = "phip1611's common libraries, modules, and configurations for Nix and NixOS";

  inputs = {
    ###################
    # NixOS modules and nixpkgs

    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    # Use nixpkgs-unstable instead of master so that packages are more likely
    # to be cached already while still being as fresh as possible.
    # See https://discourse.nixos.org/t/differences-between-nix-channels/13998
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    ###################
    # Web Projects

    dd-systems-meetup-website.url = "github:phip1611/dd-systems-meetup-website";
    dd-systems-meetup-website.inputs.nixpkgs.follows = "nixpkgs";

    img-to-webp-service.url = "github:phip1611/img-to-webp-spring-service";
    img-to-webp-service.inputs.nixpkgs.follows = "nixpkgs";

    slidev-slides.url = "github:phip1611/slidev-slides";
    slidev-slides.inputs.nixpkgs.follows = "nixpkgs";

    wambo-web.url = "github:phip1611/wambo-web";
    wambo-web.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      ...
    }@inputs:
    let
      # Systems definition for dev shells and exported packages,
      # independent of the NixOS configurations and modules defined here. I
      # just use "every system" here to not restrict any user. However, it
      # likely happens that certain packages don't build for/under certain
      # systems.
      systems = inputs.nixpkgs.lib.systems.flakeExposed;

      # Initializes nixpkgs with the provided overlays.
      initNixpkgs =
        nixpkgsSrc: system:
        import nixpkgsSrc {
          inherit system;
          config = { };
          overlays = builtins.attrValues self.overlays;
        };

      # Generates the typical per-system flake attributes.
      forAllSystems =
        function:
        inputs.nixpkgs.lib.genAttrs systems (
          system:
          let
            pkgs = initNixpkgs inputs.nixpkgs system;
          in
          function pkgs
        );

      # Source for the Nix libraries in ./common/nix.
      commonSrc = rec {
        base = ./common;
        nix = {
          all = "${base}/nix/default.nix";
          bootitems = "${base}/nix/bootitems";
          libutil = "${base}/nix/libutil";
          packages = "${base}/nix/packages";
        };
        modules = "${base}/modules";
      };

      # Initializer for the Nix libraries in ./common/nix.
      initCommonNix = pkgs: {
        # All unit and integration tests as combined derivation.
        allTests = (import commonSrc.nix.all { inherit pkgs; }).allTests;
        bootitems = import commonSrc.nix.bootitems { inherit pkgs; };
        libutil = import commonSrc.nix.libutil { inherit pkgs; };
        packages = import commonSrc.nix.packages { inherit pkgs; };
      };

      # Helper function to build a NixOS system with my common modules,
      # relevant special args, and the host-specific configuration.
      buildNixosSystem =
        {
          hostName, # string
          # One of the definitions of `pkgs.lib.systems.flakeExposed`:
          system,
          # Additional modules. This should only include modules that are
          # coming from a flake for consistency.
          additionalModules ? [ ],
        }:
        (inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          # specialArgs are additional arguments passed to a NixOS module
          # function. This should only include the flake inputs.
          # Apart from that, it's an anti-pattern (according to Jacek (@tfc)).
          specialArgs = inputs;
          modules =
            builtins.attrValues self.nixosModules
            ++ [
              # Other modules from Flake inputs:
              inputs.home-manager.nixosModules.home-manager

              # Enforce consistent host name.
              {
                networking.hostName = hostName;
              }

              # The idea here is to only provide one `configuration.nix` per
              # host as entry. This file then imports all other files of the
              # configuration. This way, the NixOS system and the flake
              # definitions can be better separated and the NixOS
              # configurations are less dependent on flake.nix.
              ./hosts/${hostName}/configuration.nix
            ]
            ++ additionalModules;
        });
      outputs = {
        generic = {
          # Here I simply re-export the library files without initializing
          # it with the nixpkgs input, i.e., this is no "per system" attribute.
          #
          # Use like this (nix repl example):
          # ```nix
          # :lf .
          # pkgs = import <nixpkgs> {}
          # libutil = import lib.libutil { inherit pkgs };
          # ```
          lib = {
            bootitems = commonSrc.nix.bootitems;
            libutil = commonSrc.nix.libutil;
            packages = commonSrc.nix.packages;
          };

          nixosConfigurations = {
            # My Netcup Root Server.
            asking-alexandria = buildNixosSystem {
              hostName = "asking-alexandria";
              system = "x86_64-linux";
              additionalModules = [
                inputs.nixos-hardware.nixosModules.common-cpu-amd
                inputs.nixos-hardware.nixosModules.common-pc-ssd
                ./profiles/server.nix
              ];
            };

            # My personal PC at home.
            homepc = buildNixosSystem {
              hostName = "homepc";
              system = "x86_64-linux";
              additionalModules = [
                inputs.nixos-hardware.nixosModules.common-cpu-intel
                inputs.nixos-hardware.nixosModules.common-pc-ssd
                ./profiles/dev-machine.nix
              ];
            };
          };

          nixosModules = {
            bootitems = "${commonSrc.modules}/bootitems";
            network-boot = "${commonSrc.modules}/network-boot";
            nix-binary-cache = "${commonSrc.modules}/nix-binary-cache";
            overlays = "${commonSrc.modules}/overlays";
            services = "${commonSrc.modules}/services";
            system = "${commonSrc.modules}/system";
            user-env = "${commonSrc.modules}/user-env";
          };

          overlays = {
            bootitems = import "${commonSrc.nix.bootitems}/overlay.nix";
            libutil = import "${commonSrc.nix.libutil}/overlay.nix";
            packages = import "${commonSrc.nix.packages}/overlay.nix";
          };
        };

        perSystem = {
          # $ nix build .\#checks.x86_64-linux.<attribute-name> or
          # `nix flake check` to run them all. But the latter also does more.
          checks = forAllSystems (pkgs: rec {
            inherit (initCommonNix pkgs) allTests;

            deadnix =
              pkgs.runCommand "deadnix-check"
                {
                  src = ./.;
                  nativeBuildInputs = [ pkgs.deadnix ];
                }
                ''
                  set -euo pipefail
                  deadnix -f -L $src
                  touch $out
                '';
          });

          devShells = forAllSystems (pkgs: {
            default = pkgs.mkShell {
              packages =
                with pkgs;
                [
                  jq
                  nixos-rebuild
                  nixfmt
                ]
                ++ builtins.attrValues (initCommonNix pkgs).packages;

              shellHook = ''
                # I still like the convenience of Nix paths for quick
                # prototyping. This is also what my common NixOS module
                # sets globally.
                export NIX_PATH="nixpkgs=${inputs.nixpkgs}:nixpkgs-unstable=${inputs.nixpkgs-unstable}:$NIX_PATH"
              '';
            };
          });

          # `$ nix fmt` or `$ fd --extension=nix --exec nixfmt`
          formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);

          # Exported (and runnable) packages.
          #
          # $ nix build|run .\#packages.x86_64-linux.<attribute-name>
          # $ nix build|run .\#<attribute-name>
          packages = forAllSystems (
            pkgs:
            let
              listNixosOptions = pkgs.callPackage ./utils/list-nixos-options.nix {
                inherit (inputs) self;
              };
            in
            (initCommonNix pkgs).packages
            // {
              inherit listNixosOptions;
              bootitems-combined = pkgs.symlinkJoin (
                let
                  commonNix = initCommonNix pkgs;
                in
                {
                  name = "bootitems-combined";
                  paths = [
                    commonNix.bootitems.linux.kernelsCombined
                    commonNix.bootitems.linux.initrdsCombined
                    commonNix.bootitems.tinytoykernel
                  ];
                }
              );
            }
          );
        };
      };
    in
    (outputs.generic // outputs.perSystem);
}
