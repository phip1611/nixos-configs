{ config, lib, pkgs, img-to-webp-service, ... }:

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
      {
        enableACME = true;
        http2 = true;
        http3 = true;
        quic = true; # also needed when http3 = true
        # Upgrade HTTP to HTTPS
        forceSSL = true;
        locations."/".proxyPass = "http://localhost:${port}";
      };
  };
}
