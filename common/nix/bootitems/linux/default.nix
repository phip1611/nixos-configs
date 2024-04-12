{ pkgs }:

let
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
    # List of kernel to build with the minimal config.
    [
      # Use the default stable LTS Linux kernel of that release to prevent
      # frequent unnecessary rebuilds.
      pkgs.linux
    ]
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
