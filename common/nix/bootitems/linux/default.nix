{ pkgs }:

let
  lib = pkgs.lib;

  # Makes the version name more Nix friendly, so that typical convenience
  # in a Nix repl for example still work.
  # - no "."
  # - don't start with a digit
  kernelPkgVersionToAttrFriendlyName = kernelPkg:
    "linux-${builtins.replaceStrings ["."] ["-"] kernelPkg.version}";
in
{
  kernels = builtins.foldl'
    (acc: kernelPkg: acc // {
      "${kernelPkgVersionToAttrFriendlyName kernelPkg}" = pkgs.callPackage ./build-kernel.nix {
        inherit kernelPkg;
      };
    })
    { }
    # List of kernels to build with the minimal config.
    (lib.lists.unique [
      pkgs.linux
      pkgs.linux_latest
    ])
  ;
  initrds = {
    minimal = pkgs.callPackage ./build-initrd.nix { };
    default = pkgs.callPackage ./build-initrd.nix {
      additionalPackages = with pkgs; [
        curl
        pciutils
        usbutils
        util-linux # lsblk and more
      ];
    };
  };
}
