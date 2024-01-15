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

    # Web Projects

    wambo-web.url = "github:phip1611/wambo-web";
    wambo-web.inputs.nixpkgs.follows = "nixpkgs";
    wambo-web.inputs.flake-parts.follows = "flake-parts";

    img-to-webp-service.url = "github:phip1611/img-to-webp-spring-service";
    img-to-webp-service.inputs.nixpkgs.follows = "nixpkgs";
    img-to-webp-service.inputs.flake-parts.follows = "flake-parts";
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
      commonSrc = rec {
        base = ./common;
        libutil = "${base}/libutil";
        libutilTests = "${libutil}/_test";
        module = "${base}/module";
        pkgs = "${base}/pkgs";
        pkgsTests = "${pkgs}/_test";
      };

      # Common modules originating from a flake.
      commonFlakeNixosModules = [
        home-manager.nixosModules.home-manager
        commonSrc.module
      ];

      # Helper function to build a NixOS system with my common modules,
      # relevant special args, and the host-specific configuration.
      buildNixosSystem =
        { hostName # string
          # One of the definitions of `pkgs.lib.systems.flakeExposed`:
        , system
        }:
        (
          nixpkgs.lib.nixosSystem {
            inherit system;
            # specialArgs are additional arguments passed to a NixOS module
            # function. This should only include the flake inputs itself.
            # Apart from that, it's an anti-pattern (according to Jacek (@tfc)).
            specialArgs = inputs;
            # The idea here is to only provide one `configuration.nix` per host
            # as entry. This file then imports all other files of the
            # configuration. This way, the NixOS system and the flake
            # definitions can be better separated and the NixOS configurations
            # are less dependent on flake.nix.
            modules = commonFlakeNixosModules ++
              [ ./hosts/${hostName}/configuration.nix ] ++
              # Configuration modules that bind outer properties to the NixOS
              # configuration. This way, we can keep specialArgs small.
              [
                (
                  {
                    networking.hostName = hostName;
                  }
                )
              ];
          }
        );
    in
    flake-parts.lib.mkFlake { inherit inputs; }
      {
        flake = {
          # Here I simply re-export the library files without initializing
          # it with the nixpkgs input, i.e., this is no "per system" attribute.
          lib = rec {
            default = libutil;
            libutil = commonSrc.libutil;
          };

          nixosConfigurations = {
            # My Netcup Root Server.
            asking-alexandria = buildNixosSystem {
              hostName = "asking-alexandria";
              system = "x86_64-linux";
            };

            # My personal PC at home where I've also have my Windows installed
            # (on a dedicated disk).
            homepc = buildNixosSystem {
              hostName = "homepc";
              system = "x86_64-linux";
            };

            # My main laptop.
            linkin-park = buildNixosSystem {
              hostName = "linkin-park";
              system = "x86_64-linux";
            };
          };

          nixosModules = rec {
            default = phip1611-common;
            phip1611-common = commonSrc.module;
          };

          overlays = {
            libutil = import "${commonSrc.libutil}/overlay.nix";
            pkgs = import "${commonSrc.pkgs}/overlay.nix";
          };
        };

        # Systems definition for dev shells and exported packages,
        # independent of the NixOS configurations and modules defined here. We
        # just use "every system" here to not restrict any user. However, it
        # likely happens that certain packages don't build for/under certain
        # systems.
        systems = nixpkgs.lib.systems.flakeExposed;

        perSystem = { config, pkgs, ... }:
          let
            common = {
              libutil = import commonSrc.libutil { inherit pkgs; };
              libutilTests = import commonSrc.libutilTests { inherit pkgs; };
              pkgs = import commonSrc.pkgs { inherit pkgs; };
              pkgsTests = import commonSrc.pkgsTests { inherit pkgs; };
            };
          in
          {
            # $ nix build .\#checks.x86_64-linux.<attribute-name> or
            # `nix flake check` to run them all.
            checks = rec {
              # I have this here additionally, as `nix flake check` starts
              # with the NixOS modules and sometimes I want to have quicker
              # feedback.
              allUnitTests = pkgs.symlinkJoin {
                name = "all-unit-tests";
                paths = [
                  libutilTests
                  pkgsTests
                ];
              };
              deadnix = pkgs.runCommand "deadnix-check"
                {
                  src = ./.;
                  nativeBuildInputs = [ pkgs.deadnix ];
                } ''
                set -euo pipefail

                deadnix -f -L $src

                touch $out
              '';
              inherit (common) libutilTests pkgsTests;
              /* runVm = pkgs.testers.nixosTest {
                name = "my-test";
                nodes = {
                  machine1 = { lib, pkgs, nodes, ... }: {
                    imports = [
                      home-manager.nixosModules.home-manager
                      commonSrc.module
                    ];
                    config = {
                      # nixpkgs.config.allowUnfree = true;

                      users.users."tester".isNormalUser = true;
                      phip1611 = {
                        username = "tester";
                        common = {
                          enable = true;
                          user.pkgs.cli.enable = false;
                          user.pkgs.gui.enable = false;
                        };
                      };
                    };

                  };
                  # machine2 = ...;
                };
                testScript = ''
                  start_all()
                  machine1.wait_for_unit("foo.service")
                  machine1.succeed("hello | foo-send")
                '';
              }; */
            };

            devShells = {
              default = pkgs.mkShell {
                packages = with pkgs; [
                  nixos-rebuild
                  nixpkgs-fmt
                ] ++ builtins.attrValues common.pkgs;

                shellHook = ''
                  # I still like the convenience of nix paths for quick
                  # prototyping. This is also what my common NixOS module
                  # sets globally.
                  export NIX_PATH="nixpkgs=${nixpkgs}:nixpkgs-unstable=${nixpkgs-unstable}:$NIX_PATH"
                '';
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
                inherit (pkgs) ansi lib nixos-option writeShellScriptBin writeText;
                inherit home-manager nixpkgs commonSrc;
              };
            } // common.pkgs;
          };
      };
}
