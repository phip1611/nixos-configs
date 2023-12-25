#!/usr/bin/env bash

# Script to locally test that all NixOS configs build successfully.
# This is not used in GitHub CI as all the GUI apps result in "no space left"
# errors in CI.

set -euo pipefail

SYSTEMS=(
	asking-alexandria
	homepc
	linkin-park
)

for SYSTEM in "${SYSTEMS[@]}"
do
  echo "Building nixos-config '$SYSTEM'"
  nixos-rebuild build --flake ".#$SYSTEM"
done

rm -rf ./result
