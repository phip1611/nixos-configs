#!/usr/bin/env bash

set -euo pipefail

# Transform the space-separated string into an array
IFS=' ' read -r -a DEV_SHELLS <<< "${DEV_SHELLS:-}"
IFS=' ' read -r -a FLAKES <<< "${FLAKES:-}"
IFS=' ' read -r -a ATTRIBUTES_TO_BUILD <<< "${ATTRIBUTES_TO_BUILD:-}"

echo "PWD: $PWD"

for FLAKE in "${FLAKES[@]}"; do
  echo "Flake input: $FLAKE"
  echo "Prefetch flake inputs ..."
  set +e -x
  nix flake prefetch-inputs "$FLAKE"
  set -e +x

  echo "Prefetch flake ..."
  set +e -x
  nix flake prefetch "$FLAKE"
  set -e +x
  echo
done

for SHELL in "${DEV_SHELLS[@]}"; do
  echo "Prefetch Nix flake dev shell: $SHELL"
  set +e -x
  nix develop "$SHELL" --command bash -c 'echo prefetched shell dependencies'
  set -e +x
  echo
done

for ATTR in "${ATTRIBUTES_TO_BUILD[@]}"; do
  echo "Prefetch (and possibly build) Nix flake attribute: $ATTR"
  set +e -x
  nice -n 19 -- nix build "$ATTR" --max-jobs "$(nproc --ignore=1)" --no-link
  set -e +x
  echo
done

echo "done"
