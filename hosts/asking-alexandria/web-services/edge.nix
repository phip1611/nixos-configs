# The edge container: the only web service container that is reachable from
# the internet and that can reach the internet.
{
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
