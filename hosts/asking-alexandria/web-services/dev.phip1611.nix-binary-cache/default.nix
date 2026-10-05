# The binary cache with the artifacts of this project/repository. nix-serve
# runs on the host (see ./service.nix).
let
  net = import ../net.nix;
  commonCfg = import ../nginx-common-host-config.nix;
in
{
  services.nginx.virtualHosts."nix-binary-cache.phip1611.dev" = commonCfg // {
    locations."/".proxyPass = "http://${net.host.ipv4}:${toString net.ports.nixServe}";
  };
}
