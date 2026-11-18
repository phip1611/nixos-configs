# The internet-facing web services. nginx terminates TLS for all vhosts,
# serves the static sites, and proxies to the other services, which only
# listen on the loopback interface. All of them run in the sandboxes of their
# systemd units.
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
}
