# Bundles all overlays coming from the common Nix functionality and activates
# them.

{
  config,
  lib,
  pkgs,
  ...
}@inputs:

{
  imports = [
    ../../nix/bootitems/overlay.module.nix
    ../../nix/libutil/overlay.module.nix
    ../../nix/packages/overlay.module.nix
  ];

  config = {
    phip1611 = {
      bootitems-overlay.enable = true;
      libutil-overlay.enable = true;
      packages-overlay.enable = true;
    };

    # Adds `pkgs.pkgsUnstable`: nixpkgs-unstable for "leaf" packages that I
    # want to be fresh. All modules share this instance, so nixpkgs-unstable
    # is only evaluated once.
    nixpkgs.overlays = [
      (final: _prev: {
        pkgsUnstable = import inputs.nixpkgs-unstable {
          inherit (final.stdenv.hostPlatform) system;
          config.allowUnfree = true;
        };
      })
    ];
  };
}
