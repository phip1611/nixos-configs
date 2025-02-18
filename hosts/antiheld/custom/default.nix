{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../../../profiles/server.nix
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
  };
}
