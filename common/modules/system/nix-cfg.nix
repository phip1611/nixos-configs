{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.phip1611.common.system;

  # Additional trusted binary caches. The default cache on `cache.nixos.org` is
  # always added by default and has a priority of 40.
  trustedBinaryCaches = [
    (
      # nix-community: for example, the lanzaboote project. priority is 41.
      {
        url = "https://nix-community.cachix.org";
        key = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
      })
  ];
in
{
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

        # Faster downloads from Nix binary caches (higher parallelism)
        download-buffer-size =
          512 * 1024 * 1024 # 512 MiB
        ;
        # 128 instead of 25 parallel connections for faster downloads
        http-connections = 128 # default is 25 _
        ;
        max-substitution-jobs = 128 # default is 16
        ;

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
  };
}
