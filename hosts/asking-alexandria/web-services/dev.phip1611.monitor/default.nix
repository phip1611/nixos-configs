# Proxies to the netdata instance on the host (see ../../netdata.nix).
let
  net = import ../net.nix;
  commonCfg = import ../nginx-common-host-config.nix;
in
{
  config = {
    services.nginx.virtualHosts."monitor.phip1611.dev" = commonCfg // {
      locations."/".proxyPass = "http://${net.host.ipv4}:${toString net.ports.netdata}";
      # Generated using `$ htpasswd -c <filename> <username>`. Bind-mounted
      # from the host.
      basicAuthFile = "/etc/dev.phip1611.monitor_basicauthfile";
    };
  };
}
