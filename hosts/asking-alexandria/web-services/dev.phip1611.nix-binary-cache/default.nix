# The binary cache with the artifacts of this project/repository. harmonia
# serves the host's Nix store via the host's Nix daemon.
#
# Reference: https://github.com/nix-community/harmonia
{
  ...
}:

let
  commonCfg = import ../nginx-common-host-config.nix;
  port = 5000;
in
{
  # The NixOS module already confines harmonia: it runs as a dynamic user
  # without network access (socket activation) and only gets the signing key
  # as a systemd credential.
  services.harmonia.cache = {
    enable = true;
    signKeyPaths = [ "/var/cache-priv-key.pem" ];
    settings = {
      bind = "127.0.0.1:${toString port}";
      # Lower than the default of 30 (higher value => lower priority). This
      # way, the default NixOS cache, which has a priority of 40, is always
      # preferred over my own cache.
      priority = 100;
    };
  };

  services.nginx.virtualHosts."nix-binary-cache.phip1611.dev" = commonCfg // {
    locations."/".proxyPass = "http://127.0.0.1:${toString port}";
  };
}
