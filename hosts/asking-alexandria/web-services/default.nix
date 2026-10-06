# The internet-facing web services. nginx runs on the host, where it
# terminates TLS for all vhosts and proxies to the services in the backend
# containers (see ./net.nix).
#
# Reference: https://nixos.org/manual/nixos/stable/#ch-containers
{
  pkgs,
  # Flake input used by a container's modules.
  img-to-webp-service,
  ...
}:

let
  net = import ./net.nix;

  # A backend container, as a module (see ./net.nix). Its only network is a
  # point-to-point link to the host. The host doesn't forward packets, so a
  # backend can reach neither the internet nor the other backends.
  #
  # `hostFiles` are bind-mounted read-only; `idmap` preserves their host
  # ownership despite the container's user namespace.
  mkBackend =
    name:
    {
      hostFiles ? [ ],
      specialArgs ? { },
      modules,
    }:
    let
      backend = net.backends.${name};
    in
    {
      containers.${name} = {
        autoStart = true;
        privateNetwork = true;
        hostAddress = net.host;
        localAddress = backend.ipv4;
        # Root in the container is an unprivileged user on the host.
        privateUsers = "pick";
        # `bindMounts` doesn't support mount options such as `idmap`.
        extraFlags = map (path: "--bind-ro=${path}:${path}:idmap") hostFiles;
        inherit specialArgs;
        config = {
          imports = modules;
          # Faster evaluation and the same overlays as on the host.
          nixpkgs.pkgs = pkgs;
          networking.firewall.allowedTCPPorts = [ backend.port ];
          system.stateVersion = "26.05";
        };
      };
      # Fail early with a clear message; nspawn's error is obscure.
      systemd.services."container@${name}".unitConfig.AssertPathExists = hostFiles;
    };
in
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

    # Services nginx proxies to
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

  # The nixos-container scripts configure the backends' veths. Otherwise,
  # networkd applies its stock 80-container-ve.network: a DHCP server,
  # forwarding, and masquerading, which would give the backends internet
  # access.
  systemd.network.networks."05-containers" = {
    matchConfig.Name = "ve-*";
    linkConfig.Unmanaged = true;
  };
}
