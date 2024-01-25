{ config, lib, pkgs, wambo-web, ... }:

let
  common = import ./common.nix;
in
{
  services.nginx.virtualHosts."wambo-web.de" = common.virtualHostConfig // {
    root = "${wambo-web.packages.${pkgs.system}.default}/share/wambo-web";
    locations."/" = common.securityHeadersConfig;
    # Cache settings taken from:
    # https://webdock.io/en/docs/webdock-control-panel/optimizing-performance/setting-cache-control-headers-common-content-types-nginx-and-apache
    locations."~* \.(js|css|jpg|jpeg|png|gif|js|css|ico|swf)$".extraConfig = ''
      expires 1y;
      etag off;
      add_header Cache-Control "public, no-transform";
      # Doesn't make sense anyway when build with Nix, where it always shows
      # 01.01.1970.
      if_modified_since off;
      add_header Last-Modified "";
    '';
    # No hashed filename in this project.
    locations."~* \.(webmanifest)$".extraConfig = ''
      etag on;
      add_header Cache-Control "no-cache";
    '';
    locations."~* \.(html)$".extraConfig = ''
      etag on;
      add_header Cache-Control "no-cache";
    '';
  };

}
