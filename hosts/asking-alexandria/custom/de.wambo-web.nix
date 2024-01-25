{ config, lib, pkgs, wambo-web, ... }:

let
  common = import ./common.nix;
in
{
  services.nginx.virtualHosts."wambo-web.de" = common.virtualHostConfig // {
    root = "${wambo-web.packages.${pkgs.system}.default}/share/wambo-web";
  };

}
