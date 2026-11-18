#!/usr/bin/env bash

# Script to build all bootitems exported by the Nix library.

set -euo pipefail

ARG=${1:-}

binary_cache_host=nix-binary-cache.phip1611.dev
binary_cache_user=phip1611
binary_cache_ssh_port=7331

# Populates the Nix binary cache, when not running in CI.
populate_cache() {
  if [ "$ARG" != "--ci" ]; then
    echo "Populating the Nix binary cache at $binary_cache_host"
    NIX_SSHOPTS="-p $binary_cache_ssh_port" nix copy --to ssh-ng://$binary_cache_user@$binary_cache_host --substitute-on-destination ./result
    echo "✔️ Populated the Nix binary cache at $binary_cache_host"
  fi
}

# Uses the same flake package as the hosts, so that the bootitems are built
# with the flake's overlays.
echo "Building all bootitems"
nix build .#bootitems-combined
populate_cache
