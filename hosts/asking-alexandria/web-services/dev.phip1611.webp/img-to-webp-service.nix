{
  config,
  lib,
  pkgs,
  img-to-webp-service,
  ...
}:

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
        commonCfg = import ../nginx-common-host-config.nix;
      in
      commonCfg
      // {
        locations."/".proxyPass = "http://localhost:${port}";
      };
  };
}
