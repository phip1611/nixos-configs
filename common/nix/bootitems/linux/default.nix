{ pkgs }:

{
  kernels = {
    latest = pkgs.callPackage ./build-kernel.nix {
      kernelPkg = pkgs.linux_latest;
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
