{ config, lib, pkgs, wambo-web, ... }:

let
  commonCfg = import ../nginx-common-host-config.nix;
in
{
  services.nginx.virtualHosts."wambo-web.de" = commonCfg // {
    root = "${wambo-web.packages.${pkgs.system}.default}/share/wambo-web";
  };

}
