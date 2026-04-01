#!/usr/bin/env bash

# The following @-annotations belong to https://github.com/sigoden/argc
#
# @describe
# Find all NixOS generations, sorts them, skips the latest `n` entries, and
# prints their file paths.
#
# To delete all old generations you may run:
#   `list-old-system-profiles | sudo xargs rm -rf`
#
# @option -n --skip=3
# Number of newest generations to keep
# @option -d --dir=/nix/var/nix/profiles
# Profiles directory

# Do the "argc" magic. Reference: https://github.com/sigoden/argc
eval "$(argc --argc-eval "$0" "$@")"

set -euo pipefail

find "$argc_dir" -maxdepth 1 -type l -name 'system-*-link' \
    | sed -E 's#.*/system-([0-9]+)-link#\1 &#' \
    | sort -nr \
    | awk -v skip="$argc_skip" 'NR > skip { print }' \
    | sort -n \
    | awk '{ print $2 }'
