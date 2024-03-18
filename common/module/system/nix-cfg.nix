{ config, lib, pkgs, ... }:

let
  cfg = config.phip1611.common.system;
  username = config.phip1611.username;

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
  config = lib.mkIf cfg.enable {
    nix = {
      settings = {
        # Some configs are taken from:
        # https://jackson.dev/post/nix-reasonable-defaults/
        connect-timeout = 5;
        log-lines = 25;
        min-free = 268435456; # 256 MiB
        max-free = 1073741824; # 1 GiB
        experimental-features = "nix-command flakes";
        fallback = true;
        warn-dirty = false;
        # nix optimise the store after each and every build (for the built path)
        # by replacing identical files in the store by hard links.
        auto-optimise-store = true;

        # These both options are activated for multiple reasons
        # 1) useful for developers
        # 2) recommended in https://github.com/nix-community/nix-direnv
        keep-outputs = true;
        keep-derivations = true;

        trusted-users = [ "@wheel" username ];

        substituters = map ({ url, ... }: url) trustedBinaryCaches;
        trusted-public-keys = map ({ key, ... }: key) trustedBinaryCaches;
      };

      # Garbage Collection
      gc = {
        automatic = true;
        dates = "weekly";
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
