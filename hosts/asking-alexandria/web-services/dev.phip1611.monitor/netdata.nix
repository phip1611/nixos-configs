{
  config,
  lib,
  pkgs,
  ...
}:

let
  # https://learn.netdata.cloud/docs/netdata-agent/securing-netdata-agents/web-server
  netdataPort = 19999;
  commonCfg = import ../nginx-common-host-config.nix;
in
{
  config = {
    services.nginx.virtualHosts."monitor.phip1611.dev" = commonCfg // {
      locations."/".proxyPass = "http://localhost:${toString netdataPort}";
      # Generated using `$ htpasswd -c <filename> <username>`
      basicAuthFile = "/etc/dev.phip1611.monitor_basicauthfile";
    };

    services.netdata.enable = true;
  };
}
