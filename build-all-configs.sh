#!/usr/bin/env bash

# Script to verify that all NixOS system configurations build successfully.

set -euo pipefail

binary_cache_host=nix-binary-cache.phip1611.dev
binary_cache_user=phip1611
binary_cache_ssh_port=7331

# Helper for `fn_build_nixos_system`
_fn_build_nixos_system() {
  system=$1

  echo "Building NixOS system $system ..."
  nom build ".#nixosConfigurations.$system.config.system.build.toplevel"
  echo "✔️ Successfully built NixOS system $system"

  echo "Populating the Nix binary cache at $binary_cache_host"
  NIX_SSHOPTS="-p $binary_cache_ssh_port" nix copy --to ssh://$binary_cache_user@$binary_cache_host --substitute-on-destination ./result
  echo "✔️ Populated the Nix binary cache at $binary_cache_host"
}

# Reads the NixOS systems it should build line by line from stdin and performs
# the actual action.
fn_build_nixos_system() {
  # read all lines in lines array
  while IFS= read -r line; do
      _fn_build_nixos_system "$line"
  done
}

nix flake show --json 2>/dev/null | jq -r '.nixosConfigurations | keys[]' | fn_build_nixos_system

rm -rf ./result
