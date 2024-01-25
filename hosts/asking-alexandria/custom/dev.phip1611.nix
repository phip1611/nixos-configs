{ config, lib, pkgs, ... }:

{
  services.nginx.virtualHosts."phip1611.dev" = {
    enableACME = true;
    http2 = true;
    http3 = true;
    quic = true; # also needed when http3 = true
    # Upgrade HTTP to HTTPS
    forceSSL = true;
    locations."/".return = "301 https://phip1611.de";
  };

}
