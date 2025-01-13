#!/usr/bin/env bash

# Script to verify that all NixOS system configurations build successfully.

set -euo pipefail

nix flake show --json 2>/dev/null | jq '.nixosConfigurations | keys[]' | xargs -I {} bash -c "echo 'building NixOS system {}:'; nix build .#nixosConfigurations.{}.config.system.build.toplevel"

rm -rf ./result
