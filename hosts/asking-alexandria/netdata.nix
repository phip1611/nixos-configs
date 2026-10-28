# Host monitoring, exposed under monitor.phip1611.dev (see
# ./web-services/dev.phip1611.monitor).
{
  lib,
  pkgs,
  ...
}:

{
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "netdata"
    ];

  services.netdata.enable = true;
  services.netdata.package = pkgs.netdata.override {
    withCloudUi = true;
  };
  services.netdata.config.global = {
    "memory mode" = "map";
    "debug log" = "none";
    "access log" = "none";
    "error log" = "syslog";
  };
}
