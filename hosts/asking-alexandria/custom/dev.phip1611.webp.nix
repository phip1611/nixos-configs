{ config, lib, pkgs, img-to-webp-service, ... }:

let
  common = import ./common.nix;
in
{
  imports = [
    (img-to-webp-service.nixosModules.default)
  ];
  config = {
    services.img-to-webp-service.enable = true;
    services.img-to-webp-service.port = 8027;
    services.nginx.virtualHosts."webp.phip1611.dev" =
      let
        port = toString config.services.img-to-webp-service.port;
      in
      common.virtualHostConfig // {
        locations."/".proxyPass = "http://localhost:${port}";
      };
  };
}
