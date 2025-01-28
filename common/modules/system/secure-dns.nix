# Secure DNS: System-wide DNSSEC + DNS over HTTPS (DOH)
# Reference: https://nixos.wiki/wiki/Encrypted_DNS

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.phip1611.common.system;
in
{
  config = lib.mkIf cfg.enable {
    # Wait for https://github.com/NixOS/nixpkgs/pull/377577 to be resolved
    networking.nameservers = lib.mkForce [ "127.0.0.1" ];

    # Establishes a local DNS proxy that supports various DNS encryption
    # protocols in background. Among them are DNSSEC and DNS over HTTPS (DOH).
    # This proxy will act as system-wide DNS-server. It depends on the DNS
    # server being used in backend whether DNSSEC and DoH, are actually used.
    # See server list!
    #
    # This works with and without systemd-resolved and systemd-networkd, as well
    # as with or without Tailscale DNS.
    #
    # Some interesting technical background info about DNS resolving on todays
    # Linux systems can be found here:
    # https://tailscale.com/blog/sisyphean-dns-client-linux
    services.dnscrypt-proxy2 = {
      enable = true;
      # Settings reference:
      # https://github.com/DNSCrypt/dnscrypt-proxy/blob/master/dnscrypt-proxy/example-dnscrypt-proxy.toml
      settings = {
        ipv4_servers = true;
        ipv6_servers = true;
        require_dnssec = true;

        sources.public-resolvers = {
          urls = [
            "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
            "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
          ];
          cache_file = "/var/lib/dnscrypt-proxy2/public-resolvers.md";
          minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        };
        # List chosen from. dnscrypt-proxy2 will sort this by latency but also
        # rotate the DNS servers to improve privacy.
        # https://github.com/DNSCrypt/dnscrypt-resolvers/blob/master/v3/public-resolvers.md
        server_names = [
          # German entity
          "artikel10-doh-ipv4"
          "artikel10-doh-ipv6"

          # Switzern entity, (some?) servers in Germany
          "quad9-doh-ip4-port443-nofilter-pri"
          "quad9-doh-ip6-port443-nofilter-pri"

          "cloudflare"
          "cloudflare-ipv6"

          "google"
          "google-ipv6"
        ];
      };
    };
  };
}
