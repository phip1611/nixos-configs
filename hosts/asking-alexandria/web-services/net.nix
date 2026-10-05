# Addresses of the web service containers, within 10.231.0.0/16 and
# fd97:4b75:4af6::/48 (a randomly generated ULA, RFC 4193).
let
  # Backend containers: only reachable from the edge container, via the
  # backend bridge. `id` is the last byte of the address and must be unique
  # (2-254); `port` is the TCP port of the service.
  backends = {
    nixserve = {
      id = 2;
      port = 5000;
    };
    webp = {
      id = 3;
      port = 8027;
    };
  };
in
{
  # Point-to-point link between the host and the edge container.
  host = {
    ipv4 = "10.231.0.1";
    ipv6 = "fd97:4b75:4af6::1";
  };
  edge = {
    ipv4 = "10.231.0.2";
    ipv6 = "fd97:4b75:4af6::2";
  };

  # Host services the edge container proxies to.
  ports = {
    # https://learn.netdata.cloud/docs/netdata-agent/securing-netdata-agents/web-server
    netdata = 19999;
  };

  # Bridge between the edge container and all backend containers.
  backendBridge = {
    name = "br-backends";
    # The edge container's veth on the bridge. Not `ve-*` or `vb-*`, which
    # networkd's stock container profiles would configure.
    edgeVeth = "backends";
    edgeIpv4 = "10.231.1.1";
    prefixLength = 24;
  };

  backends = builtins.mapAttrs (
    _name:
    { id, port }:
    rec {
      inherit port;
      ipv4 = "10.231.1.${toString id}";
      url = "http://${ipv4}:${toString port}";
    }
  ) backends;
}
