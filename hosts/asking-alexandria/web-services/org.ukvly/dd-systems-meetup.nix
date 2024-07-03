{ config, lib, pkgs, dd-systems-meetup-website, ... }:

let
  nginxConf = {
    enableACME = true;
    http2 = true;
    http3 = true;
    quic = true; # also needed when http3 = true
    # Upgrade HTTP to HTTPS
    forceSSL = true;
    root = "${dd-systems-meetup-website}/public";
    locations."/".tryFiles = "$uri $uri/ /index.html";
  };
in
{
  # This host is the canonical URL.
  services.nginx.virtualHosts."ukvly.org" = nginxConf;
  services.nginx.virtualHosts."dd-systems-meetup.phip1611.dev" = nginxConf;
}
