{
  config,
  lib,
  pkgs,
  wambo-web,
  ...
}:

let
  commonCfg = import ../nginx-common-host-config.nix;
  webApp = wambo-web.packages.${pkgs.system}.default;
in
{
  /*
    probably not needed as CHV can create its own tap device on the go
  networking.interfaces.tapChv = {
      # This runs before the interface is configured by NixOS
      preSetup = ''
        ip tuntap add dev tapChv mode tap user ${config.users.users.phip1611.name}
      '';
      ipv4.addresses = [
        { address = "192.168.100.1"; prefixLength = 24; }
      ];
    };*/

  services.nginx.virtualHosts."chv-example.phip1611.dev" = commonCfg // {
    locations."/".proxyPass = "http://192.168.100.2:${port}";
  };

  services.chv-webservice-example = {
  # TODO spawn cloud hypervisor with a nginx serving some static index.html
  };

}
