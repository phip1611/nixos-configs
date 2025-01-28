# Developer machine configuration.
#
# Intended for my developer machines. NixOS updates are not performed
# automatically.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = {
    phip1611 = {
      bootitems.enable = lib.mkDefault true;
      common = {
        user-env = {
          enable = lib.mkDefault true;
          withDevCAndRust = lib.mkDefault true;
          withDevJava = lib.mkDefault true;
          withDevJavascript = lib.mkDefault true;
          withDevNix = lib.mkDefault true;
          withGui = lib.mkDefault true;
          withMedia = lib.mkDefault true;
          withPerf = lib.mkDefault true;
          withPkgsJ4F = lib.mkDefault true;
          withVmms = lib.mkDefault true;
        };
        system = {
          enable = lib.mkDefault true;
          withBleedingEdgeLinux = lib.mkDefault true;
          withDocker = lib.mkDefault true;
          withSecureDns = lib.mkDefault true;
        };
      };
      nix-binary-cache.enable = lib.mkDefault true;
    };

    nix = {
      # Keep nix store populated for no/little wait times during typical work
      settings = {
        keep-outputs = true;
        keep-derivations = true;
      };
    };
  };
}
