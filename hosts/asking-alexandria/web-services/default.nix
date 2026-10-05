# The internet-facing web services and the NixOS containers they run in.
#
# Reference: https://nixos.org/manual/nixos/stable/#ch-containers
{
  lib,
  pkgs,
  ...
}:

let
  net = import ./net.nix;
  externalIface = "ens3";
  # Host side of the edge container's link.
  edgeIface = "ve-edge";

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

    ./nginx.nix

    # Hosted web projects
    ./de.wambo-web
    ./dev.phip1611.monitor
    ./dev.phip1611.nix-binary-cache
    ./dev.phip1611.slides
    # ./dev.phip1611.webp
    ./org.ukvly
  ];

  networking.nat = {
    enable = true;
    enableIPv6 = true;
    externalInterface = externalIface;
    # Outgoing traffic of the edge container, e.g., for ACME.
    internalInterfaces = [ edgeIface ];
  };

  # NAT enables IP forwarding. Only forward the port forwards and the edge
  # container's outgoing traffic (both allowed by the NAT module), so that,
  # e.g., neighbors in the same L2 segment can't route through this host or
  # reach the container directly. `filterForward` requires the nftables-based
  # firewall.
  networking.nftables.enable = true;
  networking.firewall.filterForward = true;

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
