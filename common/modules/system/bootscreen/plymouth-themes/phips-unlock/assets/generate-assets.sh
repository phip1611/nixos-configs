#!/usr/bin/env bash

set -euo pipefail

asset_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

for asset in prompt-card entry bullet; do
  magick -background none "$asset_dir/$asset.svg" "$asset_dir/$asset.png"
done
