{
  config,
  lib,
  pkgs,
  wambo-web,
  ...
}:

let
  commonCfg = import ../nginx-common-host-config.nix;
  webApp = wambo-web.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  services.nginx.virtualHosts."wambo-web.de" = commonCfg // {
    root = "${webApp}/share/wambo-web";
    locations."/".tryFiles = "$uri $uri/ /index.html";
  };

}
