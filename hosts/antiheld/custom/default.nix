{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../../../profiles/server.nix
    ./nginx.nix
    ./host-hello-celine.nix
  ];

  config = {
    phip1611 = {
      common.user-env = {
        username = "phip1611";
        git.username = "Philipp Schuster";
        git.email = "phip1611@gmail.com";
      };

      #services.ddns-update.enable = true;
      # This file should only be root-readable!
      services.ddns-update.configPath = "/home/phip1611/ddns-config.json";
    };

    # Set your time zone.
    time.timeZone = "Europe/Berlin";

    # Select internationalisation properties.
    i18n.defaultLocale = "en_US.UTF-8";

    i18n.extraLocaleSettings = {
      LC_ADDRESS = "de_DE.UTF-8";
      LC_IDENTIFICATION = "de_DE.UTF-8";
      LC_MEASUREMENT = "de_DE.UTF-8";
      LC_MONETARY = "de_DE.UTF-8";
      LC_NAME = "de_DE.UTF-8";
      LC_NUMERIC = "de_DE.UTF-8";
      LC_PAPER = "de_DE.UTF-8";
      LC_TELEPHONE = "de_DE.UTF-8";
      LC_TIME = "de_DE.UTF-8";
    };

    networking.firewall.allowedTCPPorts = [
      80 # http
      443 # https
      5201 # iperf3
    ];
    networking.firewall.allowedUDPPorts = [
      443 # http 3 / QUIC
    ];
  };
}
