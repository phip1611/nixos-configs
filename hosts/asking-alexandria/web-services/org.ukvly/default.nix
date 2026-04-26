# dd-systems-meetup website
{
  config,
  lib,
  pkgs,
  dd-systems-meetup-website,
  dd-systems-meetup-website-next,
  ...
}:

let
  commonCfg = import ../nginx-common-host-config.nix;
  nginxConf = commonCfg // {
    root = "${dd-systems-meetup-website}/public";
    locations."/".tryFiles = "$uri $uri/ /index.html";
  };
  nginxConfNext = commonCfg // {
    root = "${dd-systems-meetup-website-next}";
    locations."/".tryFiles = "$uri $uri/ /index.html";
  };
in
{
  # This host is the canonical URL.
  services.nginx.virtualHosts."ukvly.org" = nginxConf;
  services.nginx.virtualHosts."next.ukvly.org" = nginxConfNext;
}
