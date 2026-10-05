# Proxies to the netdata instance on the host (see ../../netdata.nix).
let
  # https://learn.netdata.cloud/docs/netdata-agent/securing-netdata-agents/web-server
  netdataPort = 19999;
  commonCfg = import ../nginx-common-host-config.nix;
in
{
  config = {
    services.nginx.virtualHosts."monitor.phip1611.dev" = commonCfg // {
      locations."/".proxyPass = "http://127.0.0.1:${toString netdataPort}";
      # Generated using `$ htpasswd -c <filename> <username>`. Bind-mounted
      # from the host.
      basicAuthFile = "/etc/dev.phip1611.monitor_basicauthfile";
    };
  };
}
