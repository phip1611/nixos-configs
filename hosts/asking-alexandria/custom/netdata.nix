{ config, lib, pkgs, img-to-webp-service, ... }:

let
  # https://learn.netdata.cloud/docs/netdata-agent/securing-netdata-agents/web-server
  netdataPort = 19999;
in
{
  config = {
    services.nginx.virtualHosts."monitor.phip1611.dev" = {
      enableACME = true;
      http2 = true;
      http3 = true;
      quic = true; # also needed when http3 = true
      # Upgrade HTTP to HTTPS
      forceSSL = true;
      locations."/".proxyPass = "http://localhost:${toString netdataPort}";
      # Generated using `$ htpasswd -c <filename> <username>`
      basicAuthFile = "/etc/dev.phip1611.monitor_basicauthfile";
    };

    services.netdata.enable = true;
  };
}
