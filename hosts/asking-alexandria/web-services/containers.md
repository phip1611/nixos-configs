# Web Service Containers of asking-alexandria

nginx runs on the host, in the sandbox of its systemd unit. It terminates TLS
for all vhosts, serves the static sites, and proxies to the other web
services. Those that hold secrets run in NixOS containers, the **backends**.
They are defined in [`default.nix`](./default.nix), their addresses in
[`net.nix`](./net.nix).

Each backend container has

- a user namespace: root in the container is an unprivileged user on the
  host.
- a private network: a point-to-point link to the host, as described in the
  NixOS manual. The host doesn't forward packets, so there is no NAT, bridge,
  or routing involved.

```
                              internet
                                 |
                                 | TCP 80/443, UDP 443 (HTTP/3)
                                 v
+--------------------------------+-----------------------------------+
| host                           |                                   |
|                                v                                   |
|        +-------------------------------------+                     |
|        | nginx (TLS, ACME), static sites     +---> netdata         |
|        +--------+-------------------+--------+     127.0.0.1:19999 |
|                 |                   |                              |
|                 |                   +---> img-to-webp              |
|                 |                         127.0.0.1:8027           |
|     ve-nixserve: 10.231.1.1                                        |
+-----------------+--------------------------------------------------+
                  |
       +----------+--------+
       | nixserve          |
       | 10.231.1.2        |
       | nix-serve :5000   |
       | signing key       |
       +-------------------+
```

## Traffic

- **nginx:** It proxies to the backends via their links and to netdata and
  img-to-webp-service via the loopback interface.
- **Backends:** Their firewalls only open the port of their service. They can
  reach neither the internet nor each other, as the host doesn't forward
  packets. On the host, they only reach the ports the firewall opens for
  everyone, e.g., SSH.

## Access From the Host

The containers run no SSH server. Enter them from the host as root instead;
this uses the container's namespaces, not the network:

```sh
sudo nixos-container root-login nixserve
sudo nixos-container run nixserve -- systemctl status nix-serve
journalctl -M nixserve -u nix-serve
```

## Adding a Backend Container

1. Add an entry to `backends` in [`net.nix`](./net.nix) with an unused `id`
   (last byte of the address) and the service's TCP port.
2. Add `mkBackend "<name>" { modules = [ ... ]; }` to `imports` in
   [`default.nix`](./default.nix).
3. Proxy to `net.backends.<name>.url` in the vhost, and import the vhost in
   [`default.nix`](./default.nix).
