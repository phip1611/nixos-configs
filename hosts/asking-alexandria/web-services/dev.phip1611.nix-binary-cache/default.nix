# The binary cache with the artifacts of this project/repository. nix-serve
# serves the host's Nix store via the host's Nix daemon.
#
# Reference: https://nixos.wiki/wiki/Binary_Cache
{
  pkgs,
  ...
}:

let
  commonCfg = import ../nginx-common-host-config.nix;
  port = 5000;
in
{
  services.nix-serve = {
    enable = true;
    bindAddress = "127.0.0.1";
    inherit port;
    # Drop-in replacement on steroids
    # https://github.com/aristanetworks/nix-serve-ng
    package = pkgs.nix-serve-ng;
    # Lower than the default of 30 (higher value => lower priority). This way,
    # the default NixOS cache, which has a priority of 40, is always preferred
    # over my own cache.
    extraParams = "--priority 100";
    secretKeyFile = "/var/cache-priv-key.pem";
  };

  # The NixOS module only runs nix-serve as a dynamic user, which already
  # makes the file system read-only. This confines it further, as it holds
  # the signing key.
  systemd.services.nix-serve.serviceConfig = {
    # Apart from nginx, it only talks to the Nix daemon via its socket.
    IPAddressDeny = "any";
    IPAddressAllow = "localhost";
    RestrictAddressFamilies = [
      "AF_UNIX"
      "AF_INET"
      "AF_INET6"
    ];

    CapabilityBoundingSet = "";
    PrivateUsers = true;
    PrivateDevices = true;
    PrivateIPC = true;
    PrivatePIDs = true;
    ProtectHome = true;
    ProtectProc = "invisible";
    ProcSubset = "pid";
    NoExecPaths = [ "/" ];
    ExecPaths = [ "/nix/store" ];

    ProtectClock = true;
    ProtectControlGroups = "strict";
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    RestrictNamespaces = true;
    RestrictRealtime = true;
    LockPersonality = true;
    # The GHC runtime needs W+X memory to stream NARs.
    MemoryDenyWriteExecute = false;
    SystemCallArchitectures = "native";
    SystemCallFilter = [
      "@system-service"
      "~@privileged"
      "~@resources"
    ];
  };

  services.nginx.virtualHosts."nix-binary-cache.phip1611.dev" = commonCfg // {
    locations."/".proxyPass = "http://127.0.0.1:${toString port}";
  };
}
