{
  config,
  lib,
  pkgs,
  ...
}:

{
  phip1611 = {
    common = {
      user-env = {
        username = "phip1611";
        git.username = "Philipp Schuster";
        git.email = "phip1611@gmail.com";
      };
    };
  };

  # Make my USB WiFi dongles work:
  # - TP-Link Archer T3U Nano:
  #   Needs the driver "88x2bu" to be loaded, then it works.
  # - TP-Link Archer TX20U Nano:
  #   Needs the driver "8852bu" to be loaded, but this dongle is special. At
  #   first, it appears as storage device with the Windows driver files on it.
  #   It presents the USB vendor/product ID 0bda:1a2b. After the "EJECT" command
  #   was sent, it presents the actual vedor/product ID 35bc:0108.

  boot.kernelModules = [
    "88x2bu" # TP-Link Archer T3U nano
    "8852au" # TP-Link Archer TX20U Nano
  ];
  boot.extraModulePackages = [
    # TP-Link Archer T3U Nano
    # Driver for chipsets rtl8812bu and rtl8822bu.
    config.boot.kernelPackages.rtl88x2bu
    # TP-Link Archer TX20U Nano
    config.boot.kernelPackages.rtl8852bu
  ];

  services.udev.extraRules =
    # Switch Archer TX20U Nano from CDROM mode (default) to WiFi mode:
    ''
      ATTR{idVendor}=="0bda", ATTR{idProduct}=="1a2b", RUN+="${lib.getExe pkgs.usb-modeswitch} -K -v 0bda -p 1a2b"
    '';

  # The required external driver (no upstream driver) does not (always)
  # compile for the latest kernel. Therefore, we use the freshest LTS kernel
  # that works.
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_12;
}
