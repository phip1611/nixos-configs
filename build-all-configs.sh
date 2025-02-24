#!/usr/bin/env bash

# The following @-annotations belong to https://github.com/sigoden/argc

# @describe
# Script to verify that all NixOS system configurations of this flake build
# successfully. Also populates the Nix binary cache at phip1611.dev.
#
# @flag --sequential Don't build configs in parallel. Useful to debug errors.
# @flag --dont-populate Don't populate the Nix binary cache
# @flag --keep Keep the result directories

set -euo pipefail

# Do the "argc" magic. Reference: https://github.com/sigoden/argc
eval "$(argc --argc-eval "$0" "$@")"

binary_cache_host=phip1611.dev
binary_cache_user=phip1611
binary_cache_ssh_port=7331

out_base=result-nixos-system

# Helper for `fn_build_nixos_system`
_fn_build_nixos_system() {
  system=$1
  out=$out_base-$system

  echo "Building NixOS system $system ..."
  nix build ".#nixosConfigurations.$system.config.system.build.toplevel" -o "$out"
  echo "✔️ Successfully built NixOS system $system"

  if [ "${argc_sequential:-0}" -eq 0  ]; then
    echo "Populating the Nix binary cache at $binary_cache_host"
    NIX_SSHOPTS="-p $binary_cache_ssh_port" nix-copy-closure --to $binary_cache_user@$binary_cache_host "$out"
    echo "✔️ Populated the Nix binary cache at $binary_cache_host"
  fi
}


# Reads the NixOS systems it should build line by line from stdin and performs
# the actual action.
fn_build_nixos_systems() {
  while IFS= read -r line; do
    if [ "${argc_sequential:-0}" -eq 1 ];
    then
      _fn_build_nixos_system "$line"
    else
      _fn_build_nixos_system "$line" &
    fi
  done

  # Synchronization point for all builds
  wait

  if [ "${argc_keep:-0}" -eq 0  ]; then
      # Remove all out links
      find . -type d -name "$out_base-" -exec rm -rf \;
  fi
}


# Build all NixOS configurations of the Flake
nix flake show --json 2>/dev/null | jq -r '.nixosConfigurations | keys[]' | fn_build_nixos_systems
