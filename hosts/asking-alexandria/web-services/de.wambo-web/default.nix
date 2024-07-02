{ config, lib, pkgs, wambo-web, ... }:

{
  services.nginx.virtualHosts."wambo-web.de" = {
    enableACME = true;
    http2 = true;
    http3 = true;
    quic = true; # also needed when http3 = true
    # Upgrade HTTP to HTTPS
    forceSSL = true;
    root = "${wambo-web.packages.${pkgs.system}.default}/share/wambo-web";
  };

}
