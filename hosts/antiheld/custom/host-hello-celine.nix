{
  config,
  lib,
  pkgs,
  ...
}:

let
  commonCfg = import ../nginx-common-host-config.nix;
  webApp = wambo-web.packages.${pkgs.system}.default;
in
{
  services.nginx.virtualHosts."hello.pi.go-phip.de" = commonCfg // {
    root = "/srv/http";
  };
}
