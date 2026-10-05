# Runs the internet-facing web services in NixOS containers. The host only
# forwards HTTP(S) traffic to the edge container, where nginx terminates TLS
# for all vhosts.
#
# Reference: https://nixos.org/manual/nixos/stable/#ch-containers
{
  lib,
  pkgs,
  # Flake inputs used by the containers' modules.
  dd-systems-meetup-website,
  slidev-slides,
  wambo-web,
  ...
}:

let
  net = import ./net.nix;
  externalIface = "ens3";
  # Host side of the edge container's link.
  edgeIface = "ve-edge";

  forwardedPorts = [
    {
      proto = "tcp";
      port = 80;
    }
    {
      proto = "tcp";
      port = 443;
    }
    # http3 / quic
    {
      proto = "udp";
      port = 443;
    }
  ];

  # A web service container, as a module. `hostFiles` are bind-mounted
  # read-only; `network` holds the container's network options.
  mkContainer =
    name:
    {
      hostFiles ? [ ],
      specialArgs ? { },
      modules,
      network,
    }:
    {
      containers.${name} = network // {
        autoStart = true;
        privateNetwork = true;
        bindMounts = lib.genAttrs hostFiles (path: {
          hostPath = path;
          isReadOnly = true;
        });
        inherit specialArgs;
        config = {
          imports = [ ./container-common.nix ] ++ modules;
          # Faster evaluation and the same overlays as on the host.
          nixpkgs.pkgs = pkgs;
        };
      };
      # Fail early with a clear message; nspawn's error is obscure.
      systemd.services."container@${name}".unitConfig.AssertPathExists = hostFiles;
    };
in
{
  imports = [
    (mkContainer "edge" {
      hostFiles = [ "/etc/dev.phip1611.monitor_basicauthfile" ];
      specialArgs = {
        inherit dd-systems-meetup-website slidev-slides wambo-web;
      };
      modules = [ ./edge.nix ];
      # Point-to-point link to the host. nixos-container also sets up the
      # default routes via the host.
      network = {
        hostAddress = net.host.ipv4;
        localAddress = net.edge.ipv4;
        hostAddress6 = net.host.ipv6;
        localAddress6 = net.edge.ipv6;
      };
    })

    ./dev.phip1611.nix-binary-cache/service.nix
  ];

  # The container reports readiness only after its boot, which includes
  # ordering missing or due ACME certificates. If that takes longer than the
  # start timeout (many new certificates, or Let's Encrypt being slow or
  # unreachable), systemd kills and restarts the container, taking nginx down
  # with it. The default of 1min is too short for that.
  containers.edge.timeoutStartSec = "5min";

  networking.nat = {
    enable = true;
    enableIPv6 = true;
    externalInterface = externalIface;
    # Outgoing traffic of the edge container, e.g., for ACME.
    internalInterfaces = [ edgeIface ];
    # Keep the public IPs of the host, so no DNS changes are needed. This also
    # preserves the client IPs for nginx.
    forwardPorts = lib.concatMap (
      { proto, port }:
      [
        {
          inherit proto;
          sourcePort = port;
          destination = "${net.edge.ipv4}:${toString port}";
        }
        {
          inherit proto;
          sourcePort = port;
          destination = "[${net.edge.ipv6}]:${toString port}";
        }
      ]
    ) forwardedPorts;
  };

  # NAT enables IP forwarding. Only forward the port forwards and the edge
  # container's outgoing traffic (both allowed by the NAT module), so that,
  # e.g., neighbors in the same L2 segment can't route through this host or
  # reach the container directly. `filterForward` requires the nftables-based
  # firewall.
  networking.nftables.enable = true;
  networking.firewall.filterForward = true;

  # Host services nginx in the edge container proxies to.
  networking.firewall.interfaces.${edgeIface}.allowedTCPPorts = [
    net.ports.netdata
    # Until nix-serve moves into its own container.
    net.ports.nixServe
  ];

  # The nixos-container scripts configure the veth. Otherwise, networkd applies
  # its stock 80-container-ve.network (DHCP server, masquerading, RAs).
  systemd.network.networks."05-${edgeIface}" = {
    matchConfig.Name = edgeIface;
    linkConfig.Unmanaged = true;
  };

  # With IPv6 forwarding enabled (by NAT), networkd ignores router
  # advertisements by default, which removes the default IPv6 route.
  systemd.network.networks."40-${externalIface}".networkConfig.IPv6AcceptRA = true;
}
