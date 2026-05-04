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
  system = pkgs.stdenv.hostPlatform.system;
  nginxConf = commonCfg // {
    root = dd-systems-meetup-website.packages.${system}.default;
    locations."/".tryFiles = "$uri $uri/ /index.html";
  };
in
{
  # This host is the canonical URL.
  services.nginx.virtualHosts."ukvly.org" = nginxConf;
}
