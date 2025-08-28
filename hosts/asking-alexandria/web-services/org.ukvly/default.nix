# dd-systems-meetup website
{
  config,
  lib,
  pkgs,
  dd-systems-meetup-website,
  ...
}:

let
  commonCfg = import ../nginx-common-host-config.nix;
  nginxConf = commonCfg // {
    root = "${dd-systems-meetup-website}/public";
    locations."/".tryFiles = "$uri $uri/ /index.html";
  };
in
{
  # This host is the canonical URL.
  services.nginx.virtualHosts."ukvly.org" = nginxConf;
  services.nginx.virtualHosts."dd-systems-meetup.phip1611.dev" = nginxConf;
}
