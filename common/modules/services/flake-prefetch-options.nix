{ config, lib, ... }:

with lib;
{
  options = {
    url = lib.mkOption {
      type = lib.types.singleLineStr;
      description = "List of URLs that should be prefetched (and possibly prebuild) using `nix flake`. This includes each flake's dependencies and works for non-flake targets (such as Tarballs).";
      default = "github:phip1611/nixos-configs";
      example = "github:phip1611/nixos-configs";
    };
    devShells = lib.mkOption {
      type = lib.types.listOf lib.types.singleLineStr;
      description = "List of dev shells (attribute names) to prefetch and build (for the host's system)";
      default = [ ];
      example = [ "default" ];
    };
  };
}
