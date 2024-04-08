{ pkgs }:

{
  kernels = {
    latest = pkgs.callPackage ./build-kernel.nix {
      # Use the default stable LTS Linux kernel of that release to prevent
      # frequent unnecessary rebuilds.
      kernelPkg = pkgs.linux;
    };
  };
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
