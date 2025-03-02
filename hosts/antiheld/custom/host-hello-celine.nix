{
  config,
  lib,
  pkgs,
  ...
}:

let
  commonCfg = import ../nginx-common-host-config.nix;
in
{
  services.nginx.virtualHosts."hello.pi.go-phip.de" = commonCfg // {
    root = "/srv/http";
  };
}
