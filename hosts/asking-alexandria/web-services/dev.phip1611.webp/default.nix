# img-to-webp-service. It runs on the host, as the sandbox of its systemd unit
# confines it like a backend container, except for the network.
{
  img-to-webp-service,
  ...
}:

let
  commonCfg = import ../nginx-common-host-config.nix;
  port = 8027;
in
{
  imports = [
    img-to-webp-service.nixosModules.default
  ];

  services.img-to-webp-service = {
    enable = true;
    inherit port;
  };

  systemd.services.img-to-webp-service = {
    # Spring listens on all interfaces by default.
    environment.SERVER_ADDRESS = "127.0.0.1";
    # The service doesn't need the network apart from nginx. This blocks
    # outgoing connections, except to services on the loopback interface.
    serviceConfig = {
      IPAddressDeny = "any";
      IPAddressAllow = "localhost";
    };
  };

  services.nginx.virtualHosts."webp.phip1611.dev" = commonCfg // {
    locations."/".proxyPass = "http://127.0.0.1:${toString port}";
  };
}
