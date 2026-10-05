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

  # A backend container, as a module (see ./net.nix). It's attached to the
  # backend bridge, and its firewall only lets the host connect to the
  # service. The host doesn't forward packets, so the backend can't reach the
  # internet.
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
            # Like on the host; enables `extraInputRules`.
            networking.nftables.enable = true;
            networking.firewall.extraInputRules = ''
              ip saddr ${net.backendBridge.hostIpv4} tcp dport ${toString backend.port} accept
            '';
          }
        ];
        network = {
          privateNetwork = true;
          hostBridge = net.backendBridge.name;
          localAddress = "${backend.ipv4}/${toString net.backendBridge.prefixLength}";
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

  networking.nftables.enable = true;

  # The bridge between the host and the backend containers.
  networking.bridges.${net.backendBridge.name}.interfaces = [ ];
  networking.interfaces.${net.backendBridge.name} = {
    useDHCP = false;
    ipv4.addresses = [
      {
        address = net.backendBridge.hostIpv4;
        inherit (net.backendBridge) prefixLength;
      }
    ];
  };
}
