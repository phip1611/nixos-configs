#!/usr/bin/env bash

# The following @-annotations belong to https://github.com/sigoden/argc
#
# @describe
# Find all NixOS generations, sorts them, skips the latest `n` entries, and
# prints their file paths.
#
# To delete all old generations you may run:
#   `list-old-system-profiles | sudo xargs -d '\n' rm -rf`
#
# @option -n --skip=3
# Number of newest generations to keep
# @option -d --dir=/nix/var/nix/profiles
# Profiles directory

# Do the "argc" magic. Reference: https://github.com/sigoden/argc
eval "$(argc --argc-eval "$0" "$@")"

set -euo pipefail

# Never list the current generation (e.g., after a rollback) or the booted
# one, even if they are older than the newest `n` entries.
current=""
if [ -L "$argc_dir/system" ]; then
  current=$(basename "$(readlink "$argc_dir/system")")
fi
booted=""
if [ -L /run/booted-system ]; then
  booted=$(readlink /run/booted-system)
fi

find "$argc_dir" -maxdepth 1 -type l -name 'system-*-link' |
  sed -E 's#.*/system-([0-9]+)-link#\1 &#' |
  sort -nr |
  awk -v skip="$argc_skip" 'NR > skip { print }' |
  sort -n |
  cut -d' ' -f2- |
  while IFS= read -r link; do
    if [ "$(basename "$link")" = "$current" ] ||
      [ "$(readlink "$link")" = "$booted" ]; then
      continue
    fi
    echo "$link"
  done
