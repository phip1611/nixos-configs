#!/usr/bin/env bash

# Script to locally test that all NixOS configs build successfully.

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
