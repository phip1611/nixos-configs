{ pkgs }:

{
  # Attribute set with kernel version to built minimal kernel.
  kernels =
    let
      kernelSourceTrees = pkgs.lib.lists.unique [
        pkgs.linux
        pkgs.linux_latest
      ];

      # Makes the version name more Nix friendly, so that typical convenience
      # in a Nix repl for example still work.
      # - no "."
      # - don't start with a digit
      kernelPkgVersionToAttrFriendlyName = kernelPkg:
        "linux-${builtins.replaceStrings ["."] ["-"] kernelPkg.version}";
    in
    builtins.foldl'
      (acc: kernelPkg: acc //
        {
          ${kernelPkgVersionToAttrFriendlyName kernelPkg} = pkgs.callPackage ./build-kernel.nix {
            inherit kernelPkg;
          };
        }
      )
      { }
      kernelSourceTrees
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
