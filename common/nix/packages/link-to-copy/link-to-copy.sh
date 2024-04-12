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

REALPATH=$(realpath "$argc_path")

cp "$argc_path" "$argc_path".tmp
rm "$argc_path"
mv "$argc_path".tmp "$argc_path"


echo -e "Replaced symlink at $(ansi bold)$argc_path$(ansi reset) pointing to $(ansi bold)$REALPATH$(ansi reset) with a copy."
if [ "${argc_mode+x}" ]; then
  chmod "$argc_mode" "$argc_path"
fi
