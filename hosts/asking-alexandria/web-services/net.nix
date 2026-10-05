# Addresses of the web service containers. Each link between the host and a
# container, or between two containers, gets its own subnet within
# 10.231.0.0/16 and fd97:4b75:4af6::/48 (a randomly generated ULA, RFC 4193).
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
    nixServe = 5000;
  };
}
