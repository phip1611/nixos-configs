# Web Service Containers of asking-alexandria

The internet-facing web services run in NixOS containers. The containers are
defined in [`default.nix`](./default.nix), the addresses of the backends in
[`net.nix`](./net.nix). All containers use user namespaces: root in a
container is an unprivileged user on the host.

- The **edge** container runs nginx. It shares the host's network namespace,
  which is the default for NixOS containers. nginx thus listens on the host's
  addresses and uses the host's network like a process on the host, but the
  container can't change the network configuration.
- The **backend** containers have a private network. They share a bridge
  with the host.

```
                              internet
                                 |
                                 | TCP 80/443, UDP 443 (HTTP/3)
                                 v
+--------------------------------+-----------------------------------+
| host network namespace         |                                   |
|                                v                                   |
|        +-------------------------------------+                     |
|        | edge                                |     netdata         |
|        | nginx (TLS, ACME), static sites     +---> 127.0.0.1:19999 |
|        +------------------+------------------+                     |
|                           |                                        |
|                 br-backends: 10.231.1.1                            |
+---------+-----------------+----------+-----------------------------+
          | vb-nixserve                | vb-webp
          |                            |
   +------+------------+     +---------+---------+
   | nixserve          |     | webp              |
   | 10.231.1.2        |     | 10.231.1.3        |
   | nix-serve :5000   |     | img-to-webp :8027 |
   | signing key       |     |                   |
   +-------------------+     +-------------------+
```

## Traffic

- **Inbound:** nginx receives the traffic directly, as the host's firewall
  opens TCP 80/443 and UDP 443 (HTTP/3).
- **Outbound:** The edge container uses the host's network and resolver,
  e.g., for ACME.
- **Edge to backends and host:** nginx proxies to the backends via the
  bridge and to netdata via the loopback interface. The edge container can
  reach every service on the host, including those that only listen on the
  loopback interface.
- **Backends:** Their firewalls only accept the host. They can't reach the
  internet, as the host doesn't forward packets. On the host, they only
  reach the ports the firewall opens for everyone, e.g., SSH.

## Access From the Host

The containers run no SSH server. Enter them from the host as root instead;
this uses the container's namespaces, not the network:

```sh
sudo nixos-container root-login nixserve
sudo nixos-container run webp -- systemctl status img-to-webp-service
journalctl -M edge -u nginx
```

## Adding a Backend Container

1. Add an entry to `backends` in [`net.nix`](./net.nix) with an unused `id`
   (last byte of the address) and the service's TCP port.
2. Add `mkBackend "<name>" { modules = [ ... ]; }` to `imports` in
   [`default.nix`](./default.nix).
3. Proxy to `net.backends.<name>.url` in the vhost, and import the vhost in
   [`edge.nix`](./edge.nix).
