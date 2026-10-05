# The binary cache with the artifacts of this project/repository. nix-serve
# runs in the nixserve container (see ./container.nix).
let
  net = import ../net.nix;
  commonCfg = import ../nginx-common-host-config.nix;
in
{
  services.nginx.virtualHosts."nix-binary-cache.phip1611.dev" = commonCfg // {
    locations."/".proxyPass = net.backends.nixserve.url;
  };
}
