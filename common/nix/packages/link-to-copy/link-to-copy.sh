#!/usr/bin/env bash

set -euo pipefail

# The following @-annotations belong to https://github.com/sigoden/argc
#
# @describe
# Replaces a symlink with a copy of that file. Only works for regular files.
#
#
# @arg path!
# Path to file
# @option --mode
# Explicit file mode, such as `--mode 0644`. Otherwise, mode is kept.

# Do the "argc" magic. Reference: https://github.com/sigoden/argc
eval "$(argc --argc-eval "$0" "$@")"

if [ ! -h "$argc_path" ]; then
  echo -e "$(ansi bold)$(ansi yellow)Not a symbolic link: $argc_path$(ansi reset)"
  exit 1
fi

if [ ! -f "$argc_path" ]; then
  echo -e "$(ansi bold)$(ansi yellow)Not a symbolic link to a regular file: $argc_path$(ansi reset)"
  exit 1
fi

REALPATH=$(realpath "$argc_path")

# A unique temporary file never clobbers an existing file.
tmp=$(mktemp "$argc_path.XXXXXX")
cp --preserve=mode -- "$argc_path" "$tmp"
if [ "${argc_mode+x}" ]; then
  chmod "$argc_mode" "$tmp"
fi
mv -f -- "$tmp" "$argc_path"

echo -e "Replaced symlink at $(ansi bold)$argc_path$(ansi reset) pointing to $(ansi bold)$REALPATH$(ansi reset) with a copy."
