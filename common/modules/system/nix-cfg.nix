{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.phip1611.common.system;

  # Additional trusted binary caches. The one from
  # cache.nixos.org is always added by default.
  trustedBinaryCaches = [
    # nix-community: for example, the lanzaboote project has its files there.
    ({
      url = "https://nix-community.cachix.org";
      key = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
    })
  ];
in
{
  options = {
    phip1611.common.system = {
      # Warn. This service is relatively heavy and runs for a long time.
      withNixVerifyStoreService = lib.mkEnableOption "Enable the weekly Nix store verify service";
    };
  };
  config = lib.mkIf cfg.enable {
    nix = {
      # Not needed
      channel.enable = false;

      # Reference: https://nixos.org/manual/nix/stable/command-ref/conf-file
      settings = {
        connect-timeout = 3;
        log-lines = 25;
        min-free = 268435456; # 256 MiB
        max-free = 1073741824; # 1 GiB
        experimental-features = "nix-command flakes";
        fallback = true;
        warn-dirty = false;
        # nix optimise the store after each and every build (for the built path)
        # by replacing identical files in the store by hard links.
        auto-optimise-store = true;

        # These options are set in the profile modules
        # keep-outputs = true;
        # keep-derivations = true;

        trusted-users = [
          "root"
          "@wheel"
        ];

        substituters = map ({ url, ... }: url) trustedBinaryCaches;
        trusted-public-keys = map ({ key, ... }: key) trustedBinaryCaches;
      };

      # Garbage Collection
      gc = {
        automatic = true;
        dates = "weekly";
        # Runs normal garbage-collection plus removes all NixOS generations
        # that are older than the specified amount.
        options = "--delete-older-than 30d";
      };

      # Scheduled systemd service that optimizes all paths in the nix store
      # by replacing identical files in the store by hard links.
      optimise = {
        automatic = true;
      };
    };

    # I once had a case on host asking-alexandria where the Nix store was
    # corrupted due to a kernel panic during a Nix derivation build job, caused
    # by a IO uring bug in Linux 6.6. Afterwards, a few items of the store were
    # broken. Therefore, it is smart to run this service occasionally. Especially,
    # as I am a heavy NixOS user and I love bleeding edge stuff, the likelihood
    # that something breaks is not zero.
    systemd = lib.mkIf cfg.withNixVerifyStoreService {
      services.nix-verify-store = {
        description = "Nix Store Verify & Repair";
        serviceConfig = {
          ExecStart = "${config.nix.package}/bin/nix-store --verify --check-contents --repair";
          Type = "oneshot";
        };
      };
      timers.nix-verify-store = {
        timerConfig = {
          Persistent = true;
          RandomizedDelaySec = 1800;
          OnCalendar = "Sun 03:00:00";
        };
      };
    };
  };
}
