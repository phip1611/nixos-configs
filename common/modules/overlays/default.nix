# Bundles all overlays coming from the common Nix functionality and activates
# them.

{
  config,
  lib,
  pkgs,
  ...
}:

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
  };
}
