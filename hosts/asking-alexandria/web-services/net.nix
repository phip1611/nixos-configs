# Addresses of the backend containers, within 10.231.1.0/24.
let
  # Backend containers: only reachable from the host, and thus from the edge
  # container, via the backend bridge. `id` is the last byte of the address
  # and must be unique (2-254); `port` is the TCP port of the service.
  backends = {
    nixserve = {
      id = 2;
      port = 5000;
    };
    webp = {
      id = 3;
      port = 8027;
    };
  };
in
{
  # Bridge between the host and all backend containers.
  backendBridge = {
    name = "br-backends";
    hostIpv4 = "10.231.1.1";
    prefixLength = 24;
  };

  backends = builtins.mapAttrs (
    _name:
    { id, port }:
    rec {
      inherit port;
      ipv4 = "10.231.1.${toString id}";
      url = "http://${ipv4}:${toString port}";
    }
  ) backends;
}
