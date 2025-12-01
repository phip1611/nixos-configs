#!/usr/bin/env bash

set -euo pipefail

# Transform the space-separated string into an array
IFS=' ' read -r -a FLAKES <<< "$FLAKES"
IFS=' ' read -r -a DEV_SHELLS <<< "$DEV_SHELLS"

for FLAKE in "${FLAKES[@]}"; do
  echo "Flake input: $FLAKE"
  echo "Prefetch flake inputs ..."
  set +e
  nix flake prefetch-inputs "$FLAKE"
  echo "Prefetch flake ..."
  nix flake prefetch "$FLAKE"
  set -e
  echo
done

for SHELL in "${DEV_SHELLS[@]}"; do
  echo "Prefetch Nix dev shell: $SHELL"
  set +e
  nix develop "$SHELL" --command bash -c 'echo prefetched shell dependencies'
  set -e
  echo
done

echo "done"
