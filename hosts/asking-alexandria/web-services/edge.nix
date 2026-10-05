# The edge container: nginx terminates TLS for all vhosts, serves the static
# sites, and proxies to the other web services. It shares the host's network
# namespace, so nginx listens on the host's addresses and reaches the
# internet, the host's services, and the backend containers like a process on
# the host.
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

  # The host's firewall covers the shared network namespace, which the
  # container isn't allowed to configure.
  networking.firewall.enable = false;
}
