# The edge container: nginx terminates TLS for all vhosts, serves the static
# sites, and proxies to the other web services. It's the only web service
# container that is reachable from the internet and that can reach the
# internet.
{
  imports = [
    ./nginx.nix

    # Hosted web projects
    ./de.wambo-web
    ./dev.phip1611.monitor
    ./dev.phip1611.nix-binary-cache
    ./dev.phip1611.slides
    ./dev.phip1611.webp
    ./org.ukvly
  ];

  # The host's resolver (dnscrypt-proxy) only listens on the host's loopback
  # interface, which is unreachable from the container's network namespace.
  networking.useHostResolvConf = false;
  # Quad9 (DNSSEC-validating).
  networking.nameservers = [
    "9.9.9.9"
    "149.112.112.112"
    "2620:fe::fe"
    "2620:fe::9"
  ];
}
