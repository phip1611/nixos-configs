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
        enable = true;
        user-env.withDevCAndRust = false;
        user-env.withDevJava = false;
        user-env.withDevJavascript = false;
        user-env.withDevNix = false;
        user-env.withGui = false;
        user-env.withMedia = false;
        user-env.withPkgsJ4F = false;
        user-env.git.username = "Philipp Schuster";
        user-env.git.email = "phip1611@gmail.com";

        system = {
          withAutoUpgrade = true;
          withDocker = false;
        };
      };
    };
  };
}
