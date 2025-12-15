# Defines a systemd user service to prefetch Nix flake inputs from remote.
#
# The idea is to save me from unnecessary wait time when I frequently update
# my NixOS systems or fetch the latest upstream changes from this repository.
#
# As I use store optimization (hard linking) and garbage collection, the effects
# onto the Nix store should be negligible.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.phip1611.services.flake-prefetch;
  # Get package from overlay.
  pkg = pkgs.phip1611.packages.flake-prefetch.override {
    # Ensure this runs with the system's Nix toolchain.
    nix = config.nix.package;
  };
in
{
  options.phip1611.services.flake-prefetch = {
    enable = lib.mkEnableOption "Enable Nix flake-prefetch user service";
    flakes = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule (import ./flake-prefetch-options.nix { inherit config lib; })
      );
      default = [
        {
          url = "github:NixOS/nixpkgs?ref=nixos-${config.system.nixos.release}";
        }
        {
          url = "github:NixOS/nixpkgs?ref=nixpkgs-unstable";
        }
        {
          url = "github:NixOS/nixpkgs?ref=nixos-unstable";
        }
        {
          url = "github:nix-community/home-manager?ref=release-${config.system.nixos.release}";
        }
        {
          url = "github:phip1611/nixos-configs";
          devShells = [
            "default"
          ];
          attributesToBuild = [
            # Some example to test I don't break anything.
            "packages.${config.nixpkgs.system}.listNixosOptions"
          ];
        }
      ];
      description = ''
        List of flakes and flake-compatible resource URLs that should be prefetched using `nix flake`.
      '';
    };
    intervalMinutes = lib.mkOption {
      type = lib.types.int;
      description = "Interval in minutes for the service to run";
      # 4 times per hour
      default = 15;
      example = 15;
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.nix.enable;
        message = "Nix must be enabled on that machine";
      }
    ];
    systemd.user.services.flake-prefetch = {
      enable = true;
      description = "Nix flake-prefetch user service";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      environment =
        let
          # Function that builds a list of fully qualified Nix flake attribute
          # URLs from a base URL anda list of attribute names.
          fnNamesToAttributeUrls = url: attrNames: map (name: "${url}#${name}") attrNames;
          # Function that builds a list of fully qualifies Nix flake attribute
          # URLs from the given flakes definition and attribute type.
          fnQualifyFlakeAttrUrls =
            flakes: attrType:
            lib.pipe flakes [
              (lib.filter (flake: flake.${attrType} != [ ]))
              (lib.concatMap (flake: fnNamesToAttributeUrls flake.url flake.${attrType}))
            ];

          attributesToBuild = fnQualifyFlakeAttrUrls cfg.flakes "attributesToBuild";
          devShells = fnQualifyFlakeAttrUrls cfg.flakes "devShells";
          flakeUrls = map (flake: flake.url) cfg.flakes;
        in
        {
          ATTRIBUTES_TO_BUILD = lib.concatStringsSep " " attributesToBuild;
          DEV_SHELLS = lib.concatStringsSep " " devShells;
          FLAKES = lib.concatStringsSep " " flakeUrls;
        };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getExe pkg}";
      };
    };
    systemd.user.timers.flake-prefetch = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "0m";
        OnUnitActiveSec = "${toString cfg.intervalMinutes}m";
        Unit = "flake-prefetch.service";
      };
    };
  };
}
