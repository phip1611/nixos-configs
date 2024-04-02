{ config, lib, pkgs, ... }:

{
  imports = [
    ../../../profiles/server.nix

    ./nginx.nix

    # Hosted web projects
    ./img-to-webp-service.nix
    ./wambo-web.nix
  ];

  config = {
    phip1611 = {
      common = {
        user-env = {
          username = "phip1611";
          git.username = "Philipp Schuster";
          git.email = "phip1611@gmail.com";
        };
      };
    };
  };
}
