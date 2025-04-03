# Secure DNS: System-wide DNSSEC + DNS over HTTPS (DOH)
# Reference: https://nixos.wiki/wiki/Encrypted_DNS
#
# On mobile devices (laptops), I recommend the "captive-browser" [0] to get
# access to shitty login portals, such as in airports and airplanes.
# [0] https://search.nixos.org/options?channel=unstable&show=programs.captive-browser&type=packages

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
  config = lib.mkIf (cfg.enable && cfg.withSecureDns) {
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
        # Maximum log files size in MB
        log_files_max_size = 10;
        # Helpful to check if dnscrypt-proxy is actually used
        query_log.file = "/var/log/dnscrypt-proxy/query.log";
        sources.public-resolvers = {
          urls = [
            "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
            "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
          ];
          cache_file = "/var/cache/dnscrypt-proxy/public-resolvers.md";
          minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        };
        # List chosen from [0]. I only include servers/providers that:
        # - provide DNSSEC and DoH
        # - do no filtering and no logging (at least claim so)
        # - have servers in Europe
        #
        # dnscrypt-proxy will sort this by latency but also rotate the DNS
        # servers to improve privacy.
        # [0] https://github.com/DNSCrypt/dnscrypt-resolvers/blob/master/v3/public-resolvers.md
        server_names =
          [
            "artikel10-doh-ipv4"
            "artikel10-doh-ipv6"

            "dns4all-ipv4"
            "dns4all-ipv6"

            "dnscry.pt-frankfurt-ipv4"
            "dnscry.pt-frankfurt-ipv6"

            "quad9-doh-ip4-port443-nofilter-pri"
            "quad9-doh-ip6-port443-nofilter-pri"
          ]
          ++
          # Specify those as additional backup, when we don't use systemd-resolved.
          # These servers are already baked into systemd-resolved as fallback.
          lib.optionals (!config.services.resolved.enable) [
            "cloudflare"
            "cloudflare-ipv6"
            "google"
            "google-ipv6"
          ];
      };
    };

    # Set some security options for `resolved`. These are only used, if the
    # `dnscrypt-proxy` DNS server doesn't resolve a DNS request.

    # At first I wanted to use "true", then "allow-downgrade"; none can
    # resolve "x86.lol". This is the first time I encountered a problem with
    # my "secure DNS" setup since I started using it 3 months ago.
    services.resolved.dnssec = "false";
    # Use DNS over TLS when the fallback servers are used. We only use
    # opportunistic as some shitty ISPs and WiFis might block the DoT port.
    services.resolved.dnsovertls = "opportunistic";
    # DNS over HTTPS not yet supported by systemd-resolved.
    # Wait for https://github.com/systemd/systemd/pull/31537 and corresponding
    # support in NixOS
    # services.resolved.dnsoverhttps = "true";
  };
}
