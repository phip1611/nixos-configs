# img-to-webp-service, which runs in the webp container (see ./container.nix).
let
  net = import ../net.nix;
  commonCfg = import ../nginx-common-host-config.nix;
in
{
  services.nginx.virtualHosts."webp.phip1611.dev" = commonCfg // {
    locations."/".proxyPass = net.backends.webp.url;
  };
}
