{ config, lib, pkgs, ... }:

{
  imports = [
    ./nginx.nix

    # Hosted web projects
    ./img-to-webp-service.nix
    ./wambo-web.nix
  ];

  config = {
    phip1611 = {
      username = "phip1611";
      common = {
        user-env = {
          enable = true;
          withBootitems = false;
          withDevCAndRust = false;
          withDevJava = false;
          withDevJavascript = false;
          withDevNix = false;
          withGui = false;
          withMedia = false;
          withPkgsJ4F = false;
          withVmms = false;
          git.username = "Philipp Schuster";
          git.email = "phip1611@gmail.com";
        };

        system = {
          enable = true;
          withAutoUpgrade = true;
          withDocker = false;
        };
      };
    };

    # Comes with a pre-configured configuration for ssh.
    services.fail2ban.enable = true;
  };
}
