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

    /* I think that this is also a default or at least not necessary. Not sure.
       I added this once initially but also without it, restarts of the acme
       service succeed. Just keep it for a while, just to be sure.

      services.nginx.virtualHosts."acmechallenge.wambo-web.de" = {
      # Catchall vhost, will redirect users to HTTPS for all vhosts
      serverAliases = [ "*.wambo-web.de" ];
      locations."/.well-known/acme-challenge" = {
        root = "/var/lib/acme/.challenges";
      };
      locations."/" = {
        return = "301 https://$host$request_uri";
      };
    }; */
  };

}
