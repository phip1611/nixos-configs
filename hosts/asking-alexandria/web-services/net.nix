# Addresses of the backend containers. Each one has a point-to-point link to
# the host, which uses the same address on all of them.
let
  # `id` is the last byte of the address and must be unique (2-254); `port` is
  # the TCP port of the service.
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
  host = "10.231.1.1";

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
