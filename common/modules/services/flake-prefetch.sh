#!/usr/bin/env bash

set -euo pipefail

# Transform the space-separated string into an array
IFS=' ' read -r -a FLAKES <<< "$FLAKES"
IFS=' ' read -r -a DEV_SHELLS <<< "$DEV_SHELLS"

for FLAKE in "${FLAKES[@]}"; do
  echo "Flake input: $FLAKE"
  echo "Prefetch flake inputs ..."
  nix flake prefetch-inputs "$FLAKE"
  echo "Prefetch flake ..."
  nix flake prefetch "$FLAKE"
  echo
done

for SHELL in "${DEV_SHELLS[@]}"; do
  echo "Prefetch Nix dev shell: $SHELL"
  nix develop "$SHELL" --command bash -c 'echo prefetched shell dependencies'
  echo
done
