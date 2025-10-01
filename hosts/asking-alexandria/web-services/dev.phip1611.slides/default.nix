# Serve all talks from `slidev-slides` under `<talk>.slides.phip1611.dev`.
# This adds new talks dynamically, as soon as a new `talk-` package exists.
{
  config,
  lib,
  pkgs,
  slidev-slides,
  ...
}:

let
  baseDomain = "slides.phip1611.dev";
  commonCfg = import ../nginx-common-host-config.nix;

  # Attrs with all slides from all talks in `slug => drv` format.
  allSlides = lib.filterAttrs (
    name: _value: lib.hasPrefix "talk-" name
  ) slidev-slides.packages.${pkgs.system};

  # Generates a single virtual host definition for `services.nginx.virtualHosts.*`.
  genVhost = slideDrv: {
    "${slideDrv.meta.slug}.${baseDomain}" = commonCfg // {
      root = "${slideDrv}";
      locations."/".tryFiles = "$uri $uri/ /index.html";
    };
  };

  # vhost definitions for `services.nginx.virtualHosts.*`..
  vhostDefinitions = lib.concatMapAttrs (_name: slideDrv: genVhost slideDrv) allSlides;
in
{
  services.nginx.virtualHosts = vhostDefinitions;
}
