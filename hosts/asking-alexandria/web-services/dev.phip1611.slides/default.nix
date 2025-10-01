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
  slideWebApps = slidev-slides.packages.${pkgs.system}.default;

  slideDefs = [
    {
      subdomain = "eurorust-2025";
      root = "${slideWebApps}/2025-10-10-eurorust-minimal-rust-kernel";
    }
  ];

  # Generates a single virtual host definition for `services.nginx`.
  genVhost =
    slideDef:
    let
      vhost = "${slideDef.subdomain}.${baseDomain}";
    in
    {
      ${vhost} = commonCfg // {
        inherit (slideDef) root;
        locations."/".tryFiles = "$uri $uri/ /index.html";
      };
    };

  # Accumulates an attribute set with all vhost definitions.
  genVhosts = slideDefs: lib.mergeAttrsList (map genVhost slideDefs);
in
{
  services.nginx.virtualHosts = genVhosts slideDefs;
}
