# Runs the internet-facing web services in NixOS containers. nginx runs in the
# edge container, where it terminates TLS for all vhosts and proxies to the
# backend containers (see ./net.nix).
#
# Reference: https://nixos.org/manual/nixos/stable/#ch-containers
{
  pkgs,
  # Flake inputs used by the containers' modules.
  dd-systems-meetup-website,
  img-to-webp-service,
  slidev-slides,
  wambo-web,
  ...
}:

let
  net = import ./net.nix;

  # A web service container, as a module. `hostFiles` are bind-mounted
  # read-only; `idmap` preserves their host ownership despite the container's
  # user namespace. `network` holds the container's network options.
  mkContainer =
    name:
    {
      hostFiles ? [ ],
      specialArgs ? { },
      modules,
      network ? { },
    }:
    {
      containers.${name} = network // {
        autoStart = true;
        # Root in the container is an unprivileged user on the host.
        privateUsers = "pick";
        # `bindMounts` doesn't support mount options such as `idmap`.
        extraFlags = map (path: "--bind-ro=${path}:${path}:idmap") hostFiles;
        inherit specialArgs;
        config = {
          imports = modules;
          # Faster evaluation and the same overlays as on the host.
          nixpkgs.pkgs = pkgs;
          system.stateVersion = "26.05";
        };
      };
      # Fail early with a clear message; nspawn's error is obscure.
      systemd.services."container@${name}".unitConfig.AssertPathExists = hostFiles;
    };

  # A backend container, as a module (see ./net.nix). Its only network is a
  # point-to-point link to the host. The host doesn't forward packets, so a
  # backend can reach neither the internet nor the other backends.
  mkBackend =
    name: args:
    let
      backend = net.backends.${name};
    in
    mkContainer name (
      args
      // {
        modules = args.modules ++ [
          {
            networking.firewall.allowedTCPPorts = [ backend.port ];
          }
        ];
        network = {
          privateNetwork = true;
          hostAddress = net.host;
          localAddress = backend.ipv4;
        };
      }
    );
in
{
  imports = [
    # Shares the host's network namespace (the default for NixOS containers).
    (mkContainer "edge" {
      hostFiles = [ "/etc/dev.phip1611.monitor_basicauthfile" ];
      specialArgs = {
        inherit dd-systems-meetup-website slidev-slides wambo-web;
      };
      modules = [ ./edge.nix ];
    })

    (mkBackend "nixserve" {
      hostFiles = [ "/var/cache-priv-key.pem" ];
      modules = [ ./dev.phip1611.nix-binary-cache/container.nix ];
    })
    (mkBackend "webp" {
      specialArgs = {
        inherit img-to-webp-service;
      };
      modules = [ ./dev.phip1611.webp/container.nix ];
    })
  ];

  # The container reports readiness only after its boot, which includes
  # ordering missing or due ACME certificates. If that takes longer than the
  # start timeout (many new certificates, or Let's Encrypt being slow or
  # unreachable), systemd kills and restarts the container, taking nginx down
  # with it. The default of 1min is too short for that.
  containers.edge.timeoutStartSec = "5min";

  # nginx in the edge container listens in the host's network namespace.
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  networking.firewall.allowedUDPPorts = [
    443 # http3 / quic
  ];
  # Root in the edge container is unprivileged on the host and thus can't bind
  # ports below 1024 there.
  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 80;

  # The nixos-container scripts configure the backends' veths. Otherwise,
  # networkd applies its stock 80-container-ve.network: a DHCP server,
  # forwarding, and masquerading, which would give the backends internet
  # access.
  systemd.network.networks."05-containers" = {
    matchConfig.Name = "ve-*";
    linkConfig.Unmanaged = true;
  };
}
