#!/usr/bin/env bash

# Lists Rust projects and whether they were built in the last 7 days, as a
# base to free the disk space of their target directories.
#
# Usage: cargo-clean-stale [<dir>...]
#
# It checks the projects directly in the given directories, by default
# ~/dev and ~/dev/other, but not deeper.

set -euo pipefail
shopt -s nullglob

# Projects without a build in this time are inactive.
MAX_AGE_DAYS=7

# Returns success if the directory is a Rust project with a target directory
# that cargo created. Other build systems, such as Maven, also use target
# directories. A symlinked target directory is skipped, as `cargo clean`
# would only remove the link.
is_cargo_project() {
  local project=$1
  [ -f "$project/Cargo.toml" ] && [ ! -L "$project/target" ] &&
    grep -qs 'created by cargo' "$project/target/CACHEDIR.TAG"
}

# Returns success if a build modified a file or directory in the target
# directory recently. If find can't read everything, it assumes a recent
# build to stay on the safe side.
was_built_recently() {
  local target=$1 recent
  recent=$(find "$target" -mtime -"$MAX_AGE_DAYS" -print -quit) || return 0
  [ -n "$recent" ]
}

main() {
  local -a dirs
  local dir project

  dirs=("$@")
  if [ ${#dirs[@]} -eq 0 ]; then
    dirs=("$HOME/dev" "$HOME/dev/other")
  fi

  for dir in "${dirs[@]}"; do
    for project in "$dir"/*/; do
      project=${project%/}
      is_cargo_project "$project" || continue

      if was_built_recently "$project/target"; then
        echo "$project: built in the last $MAX_AGE_DAYS days"
      else
        echo "$project: not built in the last $MAX_AGE_DAYS days"
      fi
    done
  done
}

main "$@"
