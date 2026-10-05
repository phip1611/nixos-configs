# Web Service Containers of asking-alexandria

The internet-facing web services run in NixOS containers. The addresses are
defined in [`net.nix`](./net.nix), the containers in
[`default.nix`](./default.nix).

- The **edge** container runs nginx. It's the only container with a link to
  the host and thus the only one that is reachable from, and can reach, the
  internet.
- The **backend** containers share a bridge with the edge container. The host
  has no address on it.

```
                                internet
                                   |
                                   | TCP 80/443, UDP 443 (HTTP/3)
                                   v
+----------------------------------+-----------------------------------+
| host       ens3: public IPv4 (DHCP), 2a03:4000:63:d3::1/64           |
|                                  |                                   |
|                                  | DNAT to edge (IPv4 and IPv6)      |
|                                  v                                   |
|   ve-edge: 10.231.0.1, fd97:4b75:4af6::1      netdata :19999         |
|                                  |                ^                  |
|        point-to-point link to    |                |                  |
|        the host; outgoing        |                |                  |
|        traffic: NAT via ens3     |                |                  |
|              +-------------------+----------------+-----+            |
|              | edge   10.231.0.2, fd97:4b75:4af6::2     |            |
|              | nginx (TLS, ACME), static sites          |            |
|              +------------------+-----------------------+            |
|                                 | backends: 10.231.1.1               |
|                                 |                                    |
|                                 |  br-backends (no host address)     |
|         +-----------------------+---------------+                    |
|         | vb-nixserve                           | vb-webp            |
|         |                                       |                    |
|  +------+------------+               +----------+--------+           |
|  | nixserve          |               | webp              |           |
|  | 10.231.1.2        |               | 10.231.1.3        |           |
|  | nix-serve :5000   |               | img-to-webp :8027 |           |
|  | signing key       |               |                   |           |
|  +-------------------+               +-------------------+           |
+----------------------------------------------------------------------+
```

## Traffic

- **Inbound:** The host forwards TCP 80/443 and UDP 443 (HTTP/3) from `ens3`
  via DNAT to the edge container, for IPv4 and IPv6. The client IPs are
  preserved.
- **Outbound:** Only the edge container can reach the internet, e.g., for
  ACME. The host masquerades its traffic, i.e., replaces the private source
  address with its public one. DNS goes directly to Quad9.
- **Edge to backends and host:** nginx proxies to the backends via the
  bridge. Their firewalls only accept the edge container. On the host, the
  edge container can reach netdata and the ports the host opens on all
  interfaces, e.g., SSH.
- **Backends:** They can reach neither the host nor the internet.
- **Forwarded traffic:** The host drops everything except the port forwards
  and the edge container's outgoing traffic.

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
